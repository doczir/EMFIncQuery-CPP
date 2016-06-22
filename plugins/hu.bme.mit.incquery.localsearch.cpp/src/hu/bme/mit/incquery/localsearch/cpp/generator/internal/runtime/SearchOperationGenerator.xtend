package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import com.google.common.base.Joiner
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckExpressionStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.SearchOperationStub
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

class SearchOperationGenerator extends BaseGenerator {

	@Accessors(PUBLIC_GETTER) val SearchOperationStub operation;
	val MatchingFrameGenerator frameGenerator

	@Accessors(PUBLIC_GETTER) val CheckExpressionGenerator checkExpressionGenerator
	
	new(SearchOperationStub operation, MatchingFrameGenerator frameGenerator) {
			this(operation, frameGenerator, null)
	}

	new(SearchOperationStub operation, MatchingFrameGenerator frameGenerator, CheckExpressionGenerator checkExpressionGenerator) {
		this.operation = operation
		this.frameGenerator = frameGenerator

		this.checkExpressionGenerator = checkExpressionGenerator
	}

	override initialize() {
	}

	override compile() {
		operation.compileOperation
	}

	private dispatch def compileOperation(CheckInstanceOfStub operation) {
		return '''create_«CheckInstanceOfStub::NAME»(«operation.variable.toGetter», «operation.key.toTypeID»)'''
	}

	private dispatch def compileOperation(CheckSingleNavigationStub operation) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«CheckSingleNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toGetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(CheckMultiNavigationStub operation) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«CheckMultiNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toGetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}

	private dispatch def compileOperation(CheckExpressionStub operation) {
		val arguments = operation.variables.map[toGetter]
		'''create_«CheckExpressionStub::NAME»< «checkExpressionGenerator.name»(«checkExpressionGenerator.name»< «frameGenerator.frameName»>(«Joiner.on(", ").join(arguments)»))'''
	}
	
	private dispatch def compileOperation(ExtendInstanceOfStub operation) {
		return '''create_«ExtendInstanceOfStub::NAME»(«operation.variable.toSetter», «operation.key.toTypeID»)'''
	}
	
	private dispatch def compileOperation(ExtendSingleNavigationStub operation) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«ExtendSingleNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toSetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(ExtendMultiNavigationStub operation) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«ExtendMultiNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toSetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(SearchOperationStub operation) {
		return '''//NYI'''
	}

	private def toTypeID(EClassifier key) {
		'''«CppHelper::getTypeHelper(key).FQN»::type_id'''
	}
	
	private def toNavigator(EClass type, String name) {
		'''&«type.toCppName»::«name»'''		
	}
	
	private def toGetter(PVariable variable) {
		'''&«frameGenerator.frameName»::«frameGenerator.getVariableName(variable)»'''
	}
	
	private def toSetter(PVariable variable) {
		'''&«frameGenerator.frameName»::«frameGenerator.getVariableName(variable)»'''
	}

	private def toCppName(EClassifier type) {
		CppHelper::getTypeHelper(type).FQN
	}
	
	private def toRelationName(EStructuralFeature key) {
		key.name
	}
}
