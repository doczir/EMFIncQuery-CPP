package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import org.eclipse.emf.ecore.EClassifier
import hu.bme.mit.cpp.util.util.CppHelper

class NameUtils {
	
	static def getPlanName(PatternStub pattern) {
		if(!pattern.bound)
			return '''unbound'''
		
		pattern.boundVariables.join('_')[it.name]
	}
	
	static def toTypeName(EClassifier type) {
		val typeHelper = CppHelper::getTypeHelper(type)
		'''«typeHelper.FQN»*'''
	}
}