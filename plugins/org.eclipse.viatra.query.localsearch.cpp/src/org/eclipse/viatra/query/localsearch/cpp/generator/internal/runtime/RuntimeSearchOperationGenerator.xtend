/*******************************************************************************
 * Copyright (c) 2014-2016 Robert Doczi, IncQuery Labs Ltd.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Robert Doczi - initial API and implementation
 *******************************************************************************/
package org.eclipse.viatra.query.localsearch.cpp.generator.internal.runtime

import org.eclipse.viatra.query.localsearch.cpp.util.util.CppHelper
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.BaseGenerator
import org.eclipse.viatra.query.localsearch.cpp.generator.model.CheckInstanceOfStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.CheckMultiNavigationStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.CheckSingleNavigationStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.ExtendInstanceOfStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.ISearchOperationStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.NACOperationStub
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * @author Robert Doczi
 */
class RuntimeSearchOperationGenerator extends BaseGenerator {

	val String queryName
	@Accessors(PUBLIC_GETTER) val ISearchOperationStub operation;
	val MatchingFrameGenerator frameGenerator
	

	
	new(String queryName, ISearchOperationStub operation, MatchingFrameGenerator frameGenerator) {
		this.queryName = queryName
		this.operation = operation
		this.frameGenerator = frameGenerator
	}

	override initialize() {
	}

	override compile(StringBuilder setupCode) {
		operation.compileOperation(setupCode)
	}

	private dispatch def compileOperation(CheckInstanceOfStub operation, StringBuilder setupCode) {
		return '''create_«CheckInstanceOfStub::NAME»(«operation.variable.toGetter», «operation.key.toTypeID»)'''
	}

	private dispatch def compileOperation(CheckSingleNavigationStub operation, StringBuilder setupCode) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«CheckSingleNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toGetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(CheckMultiNavigationStub operation, StringBuilder setupCode) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«CheckMultiNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toGetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(NACOperationStub operation, StringBuilder setupCode) {
		val matcherName = '''matcher_«Math.abs(operation.hashCode)»'''
		setupCode.append('''«operation.matcher»<ModelRoot> «matcherName»(model,  «queryName.toFirstUpper»QueryGroup::instance()->context());''')
		return '''create_«NACOperationStub::NAME»<«frameGenerator.frameName»>(«matcherName», «operation.bindings.map[toGetter].join(", ")»)'''
	}

	private dispatch def compileOperation(ExtendInstanceOfStub operation, StringBuilder setupCode) {
		return '''create_«ExtendInstanceOfStub::NAME»(«operation.variable.toSetter», «operation.key.toTypeID», model)'''
	}
	
	private dispatch def compileOperation(ExtendSingleNavigationStub operation, StringBuilder setupCode) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«ExtendSingleNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toSetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(ExtendMultiNavigationStub operation, StringBuilder setupCode) {
		val sourceType = operation.matchingFrame.getVariableStrictType(operation.source) as EClass
		return '''create_«ExtendMultiNavigationStub::NAME»(«operation.source.toGetter», «operation.target.toSetter», «sourceType.toNavigator(operation.key.toRelationName)»)'''
	}
	
	private dispatch def compileOperation(ISearchOperationStub operation, StringBuilder setupCode) {
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
