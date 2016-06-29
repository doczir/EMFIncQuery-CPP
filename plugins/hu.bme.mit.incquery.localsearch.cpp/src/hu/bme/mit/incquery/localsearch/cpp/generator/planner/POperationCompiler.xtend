package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.base.Optional
import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.TypeInfo
import hu.bme.mit.incquery.localsearch.cpp.generator.model.VariableInfo
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper
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
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ISearchOperationStub

class POperationCompiler {

	val Map<PBody, MatchingFrameStub> frameMap = newHashMap
	
	var Map<PVariable, Integer> variableMapping
	var Map<PConstraint, Set<Integer>> variableBindings
	var Map<PVariable, TypeInfo> typeMapping

	var MatchingFrameStub matchingFrame
	
	
	def compile(SubPlan plan, PBody pBody, Set<PVariable> boundVariables) {
		variableMapping = CompilerHelper::createVariableMapping(plan)
		typeMapping = CompilerHelper::createTypeMapping(plan)
		variableBindings = CompilerHelper::cacheVariableBindings(plan, variableMapping, boundVariables.map[variableMapping.get(it)].toSet)

		matchingFrame = getMatchingFrame(pBody)
		
		val searchOperations = CompilerHelper::createOperationsList(plan)
			.map[compile]
			.flatten
			.toList
		return new PatternBodyStub(pBody, 0, matchingFrame, searchOperations)
	}
	
	private def getMatchingFrame(PBody pBody) {
		if(frameMap.containsKey(pBody)) {
			frameMap.get(pBody)
		} else {
			val variableToParameterMap = Maps::uniqueIndex(pBody.pattern.parameters) [pBody.getVariableByNameChecked(it.name)]
			// don't pass this to anything else or evaluate it! (Lazy evaluation!!)
			val variableInfos = pBody.uniqueVariables.map[
				new VariableInfo(Optional::fromNullable(variableToParameterMap.get(it)), it, typeMapping.get(it), variableMapping.get(it))
			].toList
			new MatchingFrameStub(variableInfos)
		}
	}

	def compile(POperation pOperation) {
		switch (pOperation) {
			PApply: {
				val pConstraint = pOperation.getPConstraint

				if(pConstraint.allBound)
					return createCheck(pConstraint)
				else
					return createExtend(pConstraint)

			}
			PStart: {
			}
			PProject: {
			}
			default: { // TODO: throw an error
			}
		}
		return #[]
	}

	def dispatch createCheck(TypeConstraint constraint) {
		val operations = <ISearchOperationStub>newArrayList
		val inputKey = constraint.supplierKey

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				operations += new CheckInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey)
			}
			EStructuralFeatureInstancesKey: {
				val src = constraint.getVariableInTuple(0)
				val trg = constraint.getVariableInTuple(1)

				val relationType = inputKey.wrappedKey

				switch (relationType) {
					case relationType.isOneToOne:
						operations += new CheckSingleNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey)
					case relationType.isOneToMany:
						operations += new CheckMultiNavigationStub(matchingFrame, src, trg, inputKey.wrappedKey)
				}
			}
		}
		
		return operations
	}

//	def dispatch createCheck(CheckPConstraint constraint, Map<PVariable, Integer> variableMapping, String patternName) {
//		pattern.addSearchOperation(new CheckExpressionStub(matchingFrame, constraint.affectedVariables, constraint.expression))
//	}

	def dispatch createCheck(ExportedParameter constraint) {
		// nop
		#[]
	}

	def dispatch createCheck(PConstraint constraint) {
		#[]
	}

	def dispatch createExtend(TypeConstraint constraint) {
		val operations = <ISearchOperationStub>newArrayList
		val inputKey = constraint.supplierKey

		// TODO : this is wasteful
		val paramPositionMap = newHashMap
		variableMapping.forEach [ variable, position |
			paramPositionMap.put(variable.name, position)
		]

		switch (inputKey) {
			EClassTransitiveInstancesKey: {
				val variable = constraint.getVariableInTuple(0)
				operations += new ExtendInstanceOfStub(matchingFrame, variable, inputKey.wrappedKey)
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
					operations += new ExtendInstanceOfStub(matchingFrame, src, inputKey.wrappedKey.EContainingClass)					
				}
				
				switch (key) {
					case key.isOneToOne:
						operations += new ExtendSingleNavigationStub(matchingFrame, src, trg, key)
					case key.isOneToMany:
						operations += new ExtendMultiNavigationStub(matchingFrame, src, trg, key)
				}
			}
		}
		return operations
	}

	def dispatch createExtend(ExportedParameter constraint) {
		// nop
		#[]
	}

	def dispatch createExtend(PConstraint constraint) {
		println("Constraint type not yet implemented: " + constraint)
		#[]
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