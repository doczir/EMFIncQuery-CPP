package hu.bme.mit.incquery.localsearch.cpp.generator.planner.util

import com.google.common.base.Objects
import com.google.common.collect.Iterables
import com.google.common.collect.Lists
import com.google.common.collect.Maps
import com.google.common.collect.Sets
import java.util.List
import java.util.Map
import java.util.Set
import java.util.stream.Collectors
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.emf.types.EClassTransitiveInstancesKey
import org.eclipse.viatra.query.runtime.emf.types.EStructuralFeatureInstancesKey
import org.eclipse.viatra.query.runtime.matchers.planning.SubPlan
import org.eclipse.viatra.query.runtime.matchers.planning.operations.PApply
import org.eclipse.viatra.query.runtime.matchers.planning.operations.POperation
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.basicdeferred.ExportedParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.basicenumerables.TypeConstraint

class CompilerHelper {
	
	static def Map<PVariable, Integer> createVariableMapping(SubPlan plan) {
		val Map<PVariable, Integer> variableMapping = Maps::newHashMap()
		val List<PVariable> symbolicParameterVariables = plan.getBody().getSymbolicParameterVariables()
		
		var variableNumber = 0
		for (PVariable pVariable : symbolicParameterVariables) {
			variableMapping.put(pVariable, variableNumber++)
		}
		// Reason for complexity here: not all variables were given back for
		// call plan.getAllDeducedVariables();
		var Set<PVariable> allVariables = Sets::newHashSet()
		var Set<PConstraint> allEnforcedConstraints = plan.getAllEnforcedConstraints()
		for (PConstraint pConstraint : allEnforcedConstraints) {
			allVariables.addAll(pConstraint.getAffectedVariables())
		}
		for (PVariable pVariable : allVariables) {
			if (!variableMapping.containsKey(pVariable)) {
				variableMapping.put(pVariable, variableNumber++)
			}
		}
		return variableMapping
	}

	static def Map<PConstraint, Set<Integer>> cacheVariableBindings(SubPlan plan_finalParam_,
		Map<PVariable, Integer> variableMappings, Set<Integer> adornment) {
		var plan = plan_finalParam_
		var Map<PConstraint, Set<Integer>> variableBindings = Maps::newHashMap()
		var Map<PConstraint, Set<PVariable>> variableBindingsDebug = Maps::newHashMap()
		var POperation operation
		while (plan.getParentPlans().size() > 0) {
			// Get the operation
			operation = plan.getOperation()
			// Get bound variables from previous plan
			plan = plan.getParentPlans().get(0)
			if (operation instanceof PApply) {
				var Set<PConstraint> enforcedConstraint = plan.getAllEnforcedConstraints()
				var Set<PVariable> allDeducedVariables = Sets::newHashSet()
				for (PConstraint pConstraint : enforcedConstraint) {
					if(!(pConstraint instanceof ExportedParameter)) allDeducedVariables.addAll(
						pConstraint.getAffectedVariables())
				}
				variableBindingsDebug.put(((operation as PApply)).getPConstraint(), allDeducedVariables)
				var Set<Integer> boundVariables = Sets::newHashSet()
				boundVariables.addAll(adornment)
				for (PVariable pVariable : allDeducedVariables) {
					boundVariables.add(variableMappings.get(pVariable))
				}
				variableBindings.put(((operation as PApply)).getPConstraint(), boundVariables)
			}
		}
		operation = plan.getOperation()
		if (operation instanceof PApply) {
			var Set<PVariable> allDeducedVariables = Sets::newHashSet()
			allDeducedVariables.addAll(((operation as PApply)).getPConstraint().getAffectedVariables())
			variableBindingsDebug.put(((operation as PApply)).getPConstraint(), allDeducedVariables)
			var Set<Integer> boundVariables = Sets::newHashSet()
			boundVariables.addAll(adornment)
			for (PVariable pVariable : allDeducedVariables) {
				boundVariables.add(variableMappings.get(pVariable))
			}
			variableBindings.put(((operation as PApply)).getPConstraint(), boundVariables)
		}
		return variableBindings
	}

	static def Map<PVariable, TypeMap> createTypeMapping(SubPlan plan) {
		val Map<PVariable, TypeMap> typeMapping = Maps::newHashMap()
		var Set<PVariable> allVarialbes = plan.getAllEnforcedConstraints().map[getAffectedVariables].flatten.toSet
		allVarialbes.forEach[pVar |
			var EClass leastStrictType = getLeastStrictType(pVar)
			if (leastStrictType !== null) {
				typeMapping.put(pVar, new TypeMap(leastStrictType, getStrictestType(pVar)))
			} else {
				var EDataType primitiveType = getPrimitiveType(pVar)
				if (primitiveType !== null) {
					typeMapping.put(pVar, new TypeMap(primitiveType, primitiveType))
				}
			}
		]
		return typeMapping
	}

	private static def EDataType getPrimitiveType(PVariable pVar) {
		return pVar.getReferringConstraintsOfType(TypeConstraint)
					.filter[variablesTuple.size == 1 || variablesTuple.get(1) === pVar]
					.map[supplierKey]
					.filter(EStructuralFeatureInstancesKey)
					.map[
						val eType = wrappedKey.EType
						switch (eType) {
							EDataType: eType
							default: null
						}
					]
					.filterNull
					.head
	}

	private static def EClass getLeastStrictType(PVariable pVar) {
		var Set<EClassifier> possibleTypes = pVar.getReferringConstraintsOfType(typeof(TypeConstraint)).stream().
			filter([constraint |
				{
					return constraint.getVariablesTuple().getSize() === 1 ||
						constraint.getVariablesTuple().get(1) === pVar
				}
			]).map([c|c.getSupplierKey()]).map([key |
				{
					if (key instanceof EClassTransitiveInstancesKey) {
						return ((key as EClassTransitiveInstancesKey)).getWrappedKey()
					} else if (key instanceof EStructuralFeatureInstancesKey) {
						return ((key as EStructuralFeatureInstancesKey)).getWrappedKey().getEType()
					}
					return null
				}
			]).filter([c|c !== null]).collect(Collectors::toSet())
		var EClass leastStrictType = null
		for (EClass type : Iterables::filter(possibleTypes, typeof(EClass))) {
			if (leastStrictType === null) {
				leastStrictType = type
			} else if(type.isSuperTypeOf(leastStrictType)) leastStrictType = type
		}
		return leastStrictType
	}

	private static def EClass getStrictestType(PVariable pVar) {
		var Set<EClassifier> possibleTypes = pVar.getReferringConstraintsOfType(typeof(TypeConstraint)).stream().
			filter([constraint |
				{
					return constraint.getVariablesTuple().getSize() === 1 ||
						constraint.getVariablesTuple().get(1) === pVar
				}
			]).map([c|c.getSupplierKey()]).map([key |
				{
					if (key instanceof EClassTransitiveInstancesKey) {
						return ((key as EClassTransitiveInstancesKey)).getWrappedKey()
					} else if (key instanceof EStructuralFeatureInstancesKey) {
						return ((key as EStructuralFeatureInstancesKey)).getWrappedKey().getEType()
					}
					return null
				}
			]).filter([c|c !== null]).collect(Collectors::toSet())
		var EClass strictestType = null
		for (EClass type : Iterables::filter(possibleTypes, typeof(EClass))) {
			if (strictestType === null) {
				strictestType = type
			} else {
				var Set<EClass> parents = Sets::newHashSet()
				parents.addAll(type.getESuperTypes())
				while (!parents.isEmpty()) {
					var EClass parent = Iterables::getFirst(parents, null)
					parents.remove(parent)
					if (parent === strictestType) {
						strictestType = type
					} else {
						parents.addAll(parent.getESuperTypes())
					}
				}
			}
		}
		return strictestType
	}

	/** 
	 * Extracts the operations from a SubPlan into a list of POperations in the
	 * order of execution
	 * @param planthe SubPlan from wich the POperations should be extracted
	 * @return list of POperations extracted from the <code>plan</code>
	 */
	static def List<POperation> createOperationsList(SubPlan plan_finalParam_) {
		var plan = plan_finalParam_
		var List<POperation> operationsList = Lists::newArrayList()
		while (plan.getParentPlans().size() > 0) {
			operationsList.add(plan.getOperation())
			var SubPlan parentPlan = plan.getParentPlans().get(0)
			plan = parentPlan
		}
		operationsList.add(plan.getOperation())
		return Lists::reverse(operationsList)
	}

	static class TypeMap {
		final EClassifier looseType
		final EClassifier strictType

		def EClassifier getLooseType() {
			return looseType
		}

		def EClassifier getStrictType() {
			return strictType
		}

		new(EClassifier looseType, EClassifier strictType) {
			super()
			this.looseType = looseType
			this.strictType = strictType
		}

		override String toString() {
			return Objects::toStringHelper(this).add("looseType", looseType.getName()).add("strictType",
				strictType.getName()).toString()
		}
	}
}
