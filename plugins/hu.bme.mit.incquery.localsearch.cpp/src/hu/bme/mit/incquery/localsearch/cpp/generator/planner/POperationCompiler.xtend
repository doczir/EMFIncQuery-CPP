package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper.TypeMap
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.emf.types.EClassTransitiveInstancesKey
import org.eclipse.viatra.query.runtime.emf.types.EStructuralFeatureInstancesKey
import org.eclipse.viatra.query.runtime.matchers.planning.SubPlan
import org.eclipse.viatra.query.runtime.matchers.planning.operations.PApply
import org.eclipse.viatra.query.runtime.matchers.planning.operations.POperation
import org.eclipse.viatra.query.runtime.matchers.planning.operations.PProject
import org.eclipse.viatra.query.runtime.matchers.planning.operations.PStart
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.basicdeferred.ExportedParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.basicenumerables.TypeConstraint

class POperationCompiler {

	val Map<PBody, MatchingFrameStub> frameMap = newHashMap
	
	var Map<PVariable, Integer> variableMapping
	var Map<PConstraint, Set<Integer>> variableBindings
	var Map<PVariable, TypeMap> typeMapping

	var MatchingFrameStub matchingFrame
	var PatternBodyStub patternBodyStub
	
	
	def void compile(SubPlan plan, PBody pBody, Set<PVariable> boundVariables, PatternBodyStub bodyStub) {
		variableMapping = CompilerHelper::createVariableMapping(plan)
		typeMapping = CompilerHelper::createTypeMapping(plan)
		variableBindings = CompilerHelper::cacheVariableBindings(plan, variableMapping, boundVariables.map[variableMapping.get(it)].toSet)

		matchingFrame = if(frameMap.containsKey(pBody)) {
			val tmpMatchingFrame = frameMap.get(pBody)
			bodyStub.matchingFrame = tmpMatchingFrame
			tmpMatchingFrame
		} else {
			val tmpMatchingFrame = new MatchingFrameStub
			frameMap.put(pBody, tmpMatchingFrame)
			bodyStub.matchingFrame = tmpMatchingFrame
			
			typeMapping.forEach [ 
				tmpMatchingFrame.addVariable($0, $1, variableMapping.get($0))
			]

			plan.body.pattern.parameters.map[plan.body.getVariableByNameChecked(it.name)].forEach [
				tmpMatchingFrame.setVariableKey(it)
			]
			tmpMatchingFrame
		}
		
		patternBodyStub = bodyStub

		CompilerHelper::createOperationsList(plan).forEach [
			compile(variableMapping)
		]
		return
	}

	def compile(POperation pOperation, Map<PVariable, Integer> variableMapping) {
		switch (pOperation) {
			PApply: {
				val pConstraint = pOperation.getPConstraint

				if(pConstraint.allBound)
					createCheck(pConstraint, variableMapping)
				else
					createExtend(pConstraint, variableMapping)

			}
			PStart: {
			}
			PProject: {
			}
			default: { // TODO: throw an error
			}
		}
	}

	def dispatch void createCheck(TypeConstraint constraint, Map<PVariable, Integer> variableMapping) {
		val inputKey = constraint.supplierKey

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				patternBodyStub.addSearchOperation(new CheckInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey))
			}
			EStructuralFeatureInstancesKey: {
				val src = constraint.getVariableInTuple(0)
				val trg = constraint.getVariableInTuple(1)

				val relationType = inputKey.wrappedKey

				switch (relationType) {
					case relationType.isOneToOne:
						patternBodyStub.addSearchOperation(new CheckSingleNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey))
					case relationType.isOneToMany:
						patternBodyStub.addSearchOperation(new CheckMultiNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey))
				}
			}
		}
	}

//	def dispatch createCheck(CheckPConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
//		pattern.addSearchOperation(new CheckExpressionStub(matchingFrame, constraint.affectedVariables, constraint.expression))
//	}

	def dispatch void createCheck(ExportedParameter constraint, Map<PVariable, Integer> variableMapping) {
		// nop
	}

	def dispatch void createCheck(PConstraint constraint, Map<PVariable, Integer> variableMapping) {
	}

	def dispatch void createExtend(TypeConstraint constraint, Map<PVariable, Integer> variableMapping) {
		val inputKey = constraint.supplierKey

		// TODO : this is wasteful
		val paramPositionMap = newHashMap
		variableMapping.forEach [ variable, position |
			paramPositionMap.put(variable.name, position)
		]

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				patternBodyStub.addSearchOperation(new ExtendInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey))
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
					patternBodyStub.addSearchOperation(new ExtendInstanceOfStub(matchingFrame, src, inputKey.wrappedKey.EContainingClass))					
				}
				
				switch (key) {
					case key.isOneToOne:
						patternBodyStub.addSearchOperation(new ExtendSingleNavigationStub(matchingFrame, src, trg, key))
					case key.isOneToMany:
						patternBodyStub.addSearchOperation(new ExtendMultiNavigationStub(matchingFrame, src, trg, key))
				}
			}
		}
	}

	def dispatch void createExtend(ExportedParameter constraint, Map<PVariable, Integer> variableMapping) {
		// nop
	}

	def dispatch void createExtend(PConstraint constraint, Map<PVariable, Integer> variableMapping) {
		println("Constraint type not yet implemented: " + constraint)
	}

	private def allBound(PConstraint pConstraint) {
		return variableBindings.get(pConstraint).containsAll(pConstraint.affectedVariables.map [
					variableMapping.get(it)
				].toSet)
	}

	private def isOneToOne(EStructuralFeature feature) {
		feature.upperBound == 1
	}
	
	private def isOneToMany(EStructuralFeature feature) {
		!feature.isOneToOne
	}
	
}