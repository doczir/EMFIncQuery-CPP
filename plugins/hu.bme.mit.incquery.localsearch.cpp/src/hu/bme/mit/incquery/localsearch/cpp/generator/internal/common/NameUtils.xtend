package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable

class NameUtils {
	
	static def getPlanName(PatternStub pattern) {
		if(!pattern.bound)
			return '''unbound'''
		
		pattern.boundParameters.join('_')[name]
	}
	
	static def toTypeName(EClassifier type) {
		val typeHelper = CppHelper::getTypeHelper(type)
		switch (type) {
			EClass: '''«typeHelper.FQN»*'''
			EDataType: '''«typeHelper.FQN»'''
		}
	}
	
	static def getPurgedName(PVariable variable) {
		var halfPurgedName = (if (!variable.virtual) {
			val regexp = Pattern::compile("_<(.)>");
			val matcher = regexp.matcher(variable.name)
			if (matcher.find)
				'''_unnamed_«matcher.group(1)»'''
			else
				variable.name
		} else
			variable.name).replace("<", "_").replace(">", "_")
		
		if(halfPurgedName.contains(".virtual")) {
			val tempName = '_' + halfPurgedName.replace(".virtual{", "")
			return tempName.substring(0, tempName.length - 1)			
		}  else 
			return halfPurgedName
	}
}