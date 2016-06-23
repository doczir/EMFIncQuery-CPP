package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import org.eclipse.emf.ecore.EClassifier
import hu.bme.mit.cpp.util.util.CppHelper
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType

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
}