package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.IPatternStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper.TypeMap
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.incquery.runtime.api.IncQueryEngine
import org.eclipse.incquery.runtime.emf.types.EClassTransitiveInstancesKey
import org.eclipse.incquery.runtime.emf.types.EStructuralFeatureInstancesKey
import org.eclipse.incquery.runtime.matchers.planning.SubPlan
import org.eclipse.incquery.runtime.matchers.planning.operations.PApply
import org.eclipse.incquery.runtime.matchers.planning.operations.POperation
import org.eclipse.incquery.runtime.matchers.planning.operations.PProject
import org.eclipse.incquery.runtime.matchers.planning.operations.PStart
import org.eclipse.incquery.runtime.matchers.psystem.PConstraint
import org.eclipse.incquery.runtime.matchers.psystem.PVariable
import org.eclipse.incquery.runtime.matchers.psystem.basicdeferred.ExportedParameter
import org.eclipse.incquery.runtime.matchers.psystem.basicenumerables.TypeConstraint
import org.eclipse.incquery.runtime.matchers.psystem.queries.PQuery

class POperationCompiler {

	var Map<PConstraint, Set<Integer>> variableBindings
	var Map<PVariable, TypeMap> typeMapping

	var MatchingFrameStub matchingFrame
	var IPatternStub pattern
	
	var Map<PQuery, MatchingFrameStub> frameMap = newHashMap;

	
	def void compile(SubPlan plan, PQuery pQuery, Set<PVariable> boundVariables, IncQueryEngine engine, QueryStub query) {
		val patternName = CaseFormat.LOWER_CAMEL.to(CaseFormat.UPPER_CAMEL, plan.body.pattern.fullyQualifiedName.removeQualifier);
		val variableMapping = CompilerHelper::createVariableMapping(plan)
		typeMapping = CompilerHelper::createTypeMapping(plan)
		variableBindings = CompilerHelper::cacheVariableBindings(plan, variableMapping, boundVariables.map[variableMapping.get(it)].toSet)

		if(frameMap.containsKey(pQuery)) {
			matchingFrame = frameMap.get(pQuery)
			query.addMatchingFrame(matchingFrame)
		}
		else {
			matchingFrame = query.addMatchingFrame
			frameMap.put(pQuery, matchingFrame)	
			
			typeMapping.forEach [ 
				matchingFrame.addVariable($0, $1, variableMapping.get($0))
			]

			plan.body.pattern.parameters.map[plan.body.getVariableByNameChecked(it.name)].forEach [
				matchingFrame.setVariableKey(it)
			]
		}
		
		if(boundVariables.empty)
			pattern = query.addSimplePattern(plan.body.pattern, matchingFrame)
		else
			pattern = query.addBoundPattern(plan.body.pattern, matchingFrame, boundVariables)

		CompilerHelper::createOperationsList(plan).forEach [
			compile(variableMapping, patternName)
		]
		return
	}

	def compile(POperation pOperation, Map<PVariable, Integer> variableMapping, String patternName) {
		switch (pOperation) {
			PApply: {
				val pConstraint = pOperation.getPConstraint

				if(variableBindings.get(pConstraint).containsAll(pConstraint.affectedVariables.map [
					variableMapping.get(it)
				].toSet))
					createCheck(pConstraint, variableMapping, patternName)
				else
					createExtend(pConstraint, variableMapping, patternName)

			}
			PStart: {
			}
			PProject: {
			}
			default: { // TODO: throw an error
			}
		}
	}

	def dispatch createCheck(TypeConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
		val inputKey = constraint.supplierKey

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				pattern.addSearchOperation(new CheckInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey))
			}
			EStructuralFeatureInstancesKey: {
				val src = constraint.getVariableInTuple(0)
				val trg = constraint.getVariableInTuple(1)

				val relationType = inputKey.wrappedKey

				switch (relationType) {
					case relationType.isOneToOne:
						pattern.addSearchOperation(new CheckSingleNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey))
					case relationType.isOneToMany:
						pattern.addSearchOperation(new CheckMultiNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey))
				}
			}
		}
	}

//	def dispatch createCheck(CheckPConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
//		pattern.addSearchOperation(new CheckExpressionStub(matchingFrame, constraint.affectedVariables, constraint.expression))
//	}

	def dispatch createCheck(ExportedParameter constraint, Map<PVariable, Integer> variableMapping,
		String patternName) {
		// nop
	}

	def dispatch createCheck(PConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
	}

	def dispatch createExtend(TypeConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
		val inputKey = constraint.supplierKey

		// TODO : this is wasteful
		val paramPositionMap = newHashMap
		variableMapping.forEach [ variable, position |
			paramPositionMap.put(variable.name, position)
		]

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				pattern.addSearchOperation(new ExtendInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey))
			}
			EStructuralFeatureInstancesKey: {
				var src = constraint.getVariableInTuple(0)
				var trg = constraint.getVariableInTuple(1)
				var key = inputKey.wrappedKey
				
				val fromBound = variableBindings.get(constraint).contains(variableMapping.get(src))
				val toBound = variableBindings.get(constraint).contains(variableMapping.get(trg))
				
				if(toBound ) {
					val tmp = src
					src = trg
					trg = tmp
					key = (key as EReference).EOpposite
				} else if (!fromBound && !toBound) {
					pattern.addSearchOperation(new ExtendInstanceOfStub(matchingFrame, src, inputKey.wrappedKey.EContainingClass))					
				}
				
				switch (key) {
					case key.isOneToOne:
						pattern.addSearchOperation(new ExtendSingleNavigationStub(matchingFrame, src, trg, key))
					case key.isOneToMany:
						pattern.addSearchOperation(new ExtendMultiNavigationStub(matchingFrame, src, trg, key))
				}
			}
//			AttributeInputKey: {
//				val src = constraint.getVariableInTuple(0)
//				val trg = constraint.getVariableInTuple(1)
//				if(inputKey.key.upperBound == 1) {
//					pattern.addSearchOperation(new ExtendSingleNavigationStub(matchingFrame, src, trg, inputKey))
//				} else {
//					pattern.addSearchOperation(
//						new ExtendMultiNavigationStub(matchingFrame, src, trg, inputKey,
//							inputKey.key.allValuesOfcppAttribute.head.subElements.filter(CPPSequence).head))
//				}
//			}
		}
	}

	def dispatch createExtend(ExportedParameter constraint, Map<PVariable, Integer> variableMapping,
		String patternName) {
		// nop
	}

	def dispatch createExtend(PConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
		println("Constraint type not yet implemented: " + constraint)
	}

	private def isOneToOne(EStructuralFeature feature) {
		feature.upperBound == 1
	}
	
	private def isOneToMany(EStructuralFeature feature) {
		!feature.isOneToOne
	}
	
	private def removeQualifier(String qualifiedString) {
		qualifiedString.substring(qualifiedString.lastIndexOf('.'));
	}

}