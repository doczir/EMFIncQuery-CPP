package hu.bme.mit.incquery.localsearch.cpp.generator.planner.util;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EClassifier;
import org.eclipse.emf.ecore.EDataType;
import org.eclipse.viatra.query.runtime.emf.types.EClassTransitiveInstancesKey;
import org.eclipse.viatra.query.runtime.emf.types.EStructuralFeatureInstancesKey;
import org.eclipse.viatra.query.runtime.matchers.planning.SubPlan;
import org.eclipse.viatra.query.runtime.matchers.planning.operations.PApply;
import org.eclipse.viatra.query.runtime.matchers.planning.operations.POperation;
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint;
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable;
import org.eclipse.viatra.query.runtime.matchers.psystem.basicdeferred.ExportedParameter;
import org.eclipse.viatra.query.runtime.matchers.psystem.basicenumerables.TypeConstraint;

import com.google.common.base.Objects;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;

public class CompilerHelper {

	public static Map<PVariable, Integer> createVariableMapping(SubPlan plan) {
		Map<PVariable, Integer> variableMapping = Maps.newHashMap();

		int variableNumber = 0;

		List<PVariable> symbolicParameterVariables = plan.getBody().getSymbolicParameterVariables();
		for (PVariable pVariable : symbolicParameterVariables) {
			variableMapping.put(pVariable, variableNumber++);
		}

		// Reason for complexity here: not all variables were given back for
		// call plan.getAllDeducedVariables();
		Set<PVariable> allVariables = Sets.newHashSet();
		Set<PConstraint> allEnforcedConstraints = plan.getAllEnforcedConstraints();
		for (PConstraint pConstraint : allEnforcedConstraints) {
			allVariables.addAll(pConstraint.getAffectedVariables());
		}
		for (PVariable pVariable : allVariables) {
			if (!variableMapping.containsKey(pVariable)) {
				variableMapping.put(pVariable, variableNumber++);
			}
		}

		return variableMapping;
	}

	public static Map<PConstraint, Set<Integer>> cacheVariableBindings(SubPlan plan,
			Map<PVariable, Integer> variableMappings, Set<Integer> adornment) {
		Map<PConstraint, Set<Integer>> variableBindings = Maps.newHashMap();
		Map<PConstraint, Set<PVariable>> variableBindingsDebug = Maps.newHashMap();

		POperation operation;
		while (plan.getParentPlans().size() > 0) {
			// Get the operation
			operation = plan.getOperation();
			// Get bound variables from previous plan
			plan = plan.getParentPlans().get(0);

			if (operation instanceof PApply) {
				Set<PConstraint> enforcedConstraint = plan.getAllEnforcedConstraints();
				Set<PVariable> allDeducedVariables = Sets.newHashSet();
				for (PConstraint pConstraint : enforcedConstraint) {
					if(!(pConstraint instanceof ExportedParameter))
						allDeducedVariables.addAll(pConstraint.getAffectedVariables());
				}

				variableBindingsDebug.put(((PApply) operation).getPConstraint(), allDeducedVariables);
				Set<Integer> boundVariables = Sets.newHashSet();
				boundVariables.addAll(adornment);
				for (PVariable pVariable : allDeducedVariables) {
					boundVariables.add(variableMappings.get(pVariable));
				}
				variableBindings.put(((PApply) operation).getPConstraint(), boundVariables);
			}
		}
		operation = plan.getOperation();
		if (operation instanceof PApply) {
			Set<PVariable> allDeducedVariables = Sets.newHashSet();
			allDeducedVariables.addAll(((PApply) operation).getPConstraint().getAffectedVariables());
			variableBindingsDebug.put(((PApply) operation).getPConstraint(), allDeducedVariables);
			Set<Integer> boundVariables = Sets.newHashSet();
			boundVariables.addAll(adornment);
			for (PVariable pVariable : allDeducedVariables) {
				boundVariables.add(variableMappings.get(pVariable));
			}
			variableBindings.put(((PApply) operation).getPConstraint(), boundVariables);
		}

		return variableBindings;
	}

	public static Map<PVariable, TypeMap> createTypeMapping(SubPlan plan) {
		Map<PVariable, TypeMap> typeMapping = Maps.newHashMap();

		Set<PVariable> allVarialbes = plan.getAllEnforcedConstraints().stream().flatMap(constraint -> {
			return constraint.getAffectedVariables().stream();
		}).collect(Collectors.toSet());

		allVarialbes.forEach(pVar -> {
			EClass leastStrictType = getLeastStrictType(pVar);
			if (leastStrictType != null) {
				typeMapping.put(pVar, new TypeMap(leastStrictType, getStrictestType(pVar)));
			} else {
				EDataType primitiveType = getPrimitiveType(pVar);

				if (primitiveType != null) {
					typeMapping.put(pVar, new TypeMap(primitiveType, primitiveType));
				}
			}
		});

		return typeMapping;
	}

	private static EDataType getPrimitiveType(PVariable pVar) {
		return Iterables.getFirst(Iterables.transform(Iterables.filter(Iterables
				.transform(Iterables.filter(pVar.getReferringConstraintsOfType(TypeConstraint.class), constraint -> {
					return constraint.getVariablesTuple().getSize() == 1
							|| constraint.getVariablesTuple().get(1) == pVar;
				}), constraint -> constraint.getSupplierKey()), EStructuralFeatureInstancesKey.class), key -> {
					EClassifier eType = key.getWrappedKey().getEType();
					return eType instanceof EDataType ? (EDataType) eType : null;
				}), null);
	}

	private static EClass getLeastStrictType(PVariable pVar) {
		Set<EClassifier> possibleTypes = pVar.getReferringConstraintsOfType(TypeConstraint.class).stream()
				.filter(constraint -> {
					return constraint.getVariablesTuple().getSize() == 1
							|| constraint.getVariablesTuple().get(1) == pVar;
				}).map(c -> c.getSupplierKey()).map(key -> {
					if (key instanceof EClassTransitiveInstancesKey) {
						return ((EClassTransitiveInstancesKey) key).getWrappedKey();
					} else if (key instanceof EStructuralFeatureInstancesKey) {
						return ((EStructuralFeatureInstancesKey) key).getWrappedKey().getEType();
					}
					return null;
				}).filter(c -> c != null).collect(Collectors.toSet());

		EClass leastStrictType = null;

		for (EClass type : Iterables.filter(possibleTypes, EClass.class)) {
			if (leastStrictType == null) {
				leastStrictType = type;
			} else if (type.isSuperTypeOf(leastStrictType))
				leastStrictType = type;
		}

		return leastStrictType;
	}

	private static EClass getStrictestType(PVariable pVar) {
		Set<EClassifier> possibleTypes = pVar.getReferringConstraintsOfType(TypeConstraint.class).stream()
				.filter(constraint -> {
					return constraint.getVariablesTuple().getSize() == 1
							|| constraint.getVariablesTuple().get(1) == pVar;
				}).map(c -> c.getSupplierKey()).map(key -> {
					if (key instanceof EClassTransitiveInstancesKey) {
						return ((EClassTransitiveInstancesKey) key).getWrappedKey();
					} else if (key instanceof EStructuralFeatureInstancesKey) {
						return ((EStructuralFeatureInstancesKey) key).getWrappedKey().getEType();
					}
					return null;
				}).filter(c -> c != null).collect(Collectors.toSet());

		EClass strictestType = null;

		for (EClass type : Iterables.filter(possibleTypes, EClass.class)) {
			if (strictestType == null) {
				strictestType = type;
			} else {
				Set<EClass> parents = Sets.newHashSet();
				parents.addAll(type.getESuperTypes());
				while (!parents.isEmpty()) {
					EClass parent = Iterables.getFirst(parents, null);
					parents.remove(parent);

					if (parent == strictestType) {
						strictestType = type;
					} else {
						parents.addAll(parent.getESuperTypes());
					}
				}
			}
		}

		return strictestType;
	}

	/**
	 * Extracts the operations from a SubPlan into a list of POperations in the
	 * order of execution
	 * 
	 * @param plan
	 *            the SubPlan from wich the POperations should be extracted
	 * @return list of POperations extracted from the <code>plan</code>
	 */
	public static List<POperation> createOperationsList(SubPlan plan) {
		List<POperation> operationsList = Lists.newArrayList();
		while (plan.getParentPlans().size() > 0) {
			operationsList.add(plan.getOperation());
			SubPlan parentPlan = plan.getParentPlans().get(0);
			plan = parentPlan;
		}
		operationsList.add(plan.getOperation());

		return Lists.reverse(operationsList);
	}

	public static class TypeMap {
		private final EClassifier looseType;
		private final EClassifier strictType;

		public EClassifier getLooseType() {
			return looseType;
		}

		public EClassifier getStrictType() {
			return strictType;
		}

		public TypeMap(EClassifier looseType, EClassifier strictType) {
			super();
			this.looseType = looseType;
			this.strictType = strictType;
		}

		@Override
		public String toString() {
			return Objects.toStringHelper(this)
				.add("looseType", looseType.getName())
				.add("strictType", strictType.getName()).toString();
		}
		
	}

}
