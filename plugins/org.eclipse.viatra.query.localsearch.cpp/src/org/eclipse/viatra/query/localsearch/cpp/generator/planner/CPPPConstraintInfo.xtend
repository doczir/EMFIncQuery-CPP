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
package org.eclipse.viatra.query.localsearch.cpp.generator.planner

import java.util.Set
import org.eclipse.viatra.query.runtime.localsearch.planner.PConstraintInfo
import org.eclipse.viatra.query.runtime.matchers.context.IInputKey
import org.eclipse.viatra.query.runtime.matchers.context.IQueryRuntimeContext
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.basicdeferred.ExportedParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.basicenumerables.ConstantValue
import org.eclipse.viatra.query.runtime.matchers.psystem.basicenumerables.TypeConstraint

/**
 * @author Robert Doczi
 */
class CPPPConstraintInfo extends PConstraintInfo{
	
	private static float MAX_COST = 250.0f
	private static float DEFAULT_COST = MAX_COST-100.0f
	
	var float cost
	
	new(PConstraint constraint, Set<PVariable> boundMaskVariables, Set<PVariable> freeMaskVariables, Set<PConstraintInfo> sameWithDifferentBindings, IQueryRuntimeContext runtimeContext) {
		super(constraint, boundMaskVariables, freeMaskVariables, sameWithDifferentBindings, runtimeContext)
	}
	
	protected override dispatch void calculateCost(ConstantValue constant) {
		cost = 1.0f;
		return;
	}

	protected override dispatch void calculateCost(TypeConstraint typeConstraint) {

		var IInputKey supplierKey = (constraint as TypeConstraint).getSupplierKey()
		var long arity = supplierKey.getArity()
		if (arity == 1) {
			// unary constraint
			calculateUnaryConstraintCost(supplierKey)
		} else if (arity == 2) {
			// binary constraint
			//var long edgeCount = runtimeContext.countTuples(supplierKey, null)
			var srcVariable = (constraint as TypeConstraint).getVariablesTuple().get(0) as PVariable
			var dstVariable = (constraint as TypeConstraint).getVariablesTuple().get(1) as PVariable
			var isInverse = false
			// Check if inverse navigation is needed along the edge
			if (freeVariables.contains(srcVariable) && boundVariables.contains(dstVariable)) {
				isInverse = true
			}
			if (freeVariables.contains(srcVariable) || freeVariables.contains(dstVariable)) {
				// This case it is not a check
				// at least one of the variables are free, so calculate cost based on the meta or/and the runtime context
				calculateBinaryExtendCost(supplierKey, srcVariable, dstVariable, isInverse, 0)
			} else {
				// It is a check operation, both variables are bound
				cost = 1.0f
			}
		} else {
			// n-ary constraint
			throw new RuntimeException('''Cost calculation for arity «arity» is not implemented yet''')
		}
	}
	
	protected override calculateBinaryExtendCost(IInputKey supplierKey, PVariable srcVariable, PVariable dstVariable, boolean isInverse, long edgeCount) {
//		var metaContext = runtimeContext.getMetaContext()
//		var Collection<InputKeyImplication> implications = metaContext.getImplications(supplierKey)
		// TODO prepare for cases when this info is not available - use only metamodel related cost calculation (see TODO at the beginning of the function)
//		var long srcCount = -1
//		var long dstCount = -1
		// Obtain runtime information
//		for (InputKeyImplication implication : implications) {
//			var List<Integer> impliedIndices = implication.getImpliedIndices()
//			if (impliedIndices.size() == 1 && impliedIndices.contains(0)) {
//				// Source key implication
//				srcCount = runtimeContext.countTuples(implication.getImpliedKey(), null)
//			} else if (impliedIndices.size() == 1 && impliedIndices.contains(1)) {
//				// Target key implication
//				dstCount = runtimeContext.countTuples(implication.getImpliedKey(), null)
//			}
//		
//		}
//		if (freeVariables.contains(srcVariable) && freeVariables.contains(dstVariable)) {
//			cost = DEFAULT_COST//dstCount * srcCount
//		} else {
//			var long srcNodeCount = -1
//			var long dstNodeCount = -1
//			if (isInverse) {
//				srcNodeCount = dstCount
//				dstNodeCount = srcCount
//			} else {
//				srcNodeCount = srcCount
//				dstNodeCount = dstCount
//			}
//			
//			if (srcNodeCount > -1 && edgeCount > -1) {
//				// The end nodes had implied (type) constraint and both nodes and adjacent edges are indexed
//				if (srcNodeCount == 0) {
//					cost = 0
//				} else {
//					cost = ((edgeCount) as float) / srcNodeCount
//				}
//			} else if (srcCount > -1 && dstCount > -1) {
//				// Both of the end nodes had implied (type) constraint
//				if(srcCount != 0) {
//					cost = dstNodeCount / srcNodeCount
//				} else {
//					// No such element exists in the model, so the traversal will backtrack at this point
//					cost = 1.0f;
//				}
//			} else {
//				// At least one of the end variables had no restricting type information
//				// Strategy: try to navigate along many-to-one relations
//				var Map<Set<PVariable>, Set<PVariable>> functionalDependencies = constraint.getFunctionalDependencies(metaContext);
//				var impliedVariables = functionalDependencies.get(boundMaskVariables)
//				if(impliedVariables != null && impliedVariables.containsAll(freeMaskVariables)){
//					cost = 1.0f;
//				} else {
//					cost = DEFAULT_COST
//				}
//			}
//		}

		if((boundVariables.contains(srcVariable) || boundVariables.contains(dstVariable)) && !((boundVariables.contains(srcVariable) && boundVariables.contains(dstVariable)))) {
			cost = 50.0f;	
		} else {
			cost = MAX_COST	
		}
	}
	
	override getCost() {
		return cost
	}
	
	override toString() {
		'''«String.format("\n")»«constraint.toString», bound variables: «boundVariables», cost: «String.format("%.2f",cost)»'''
	}
	
	protected override calculateUnaryConstraintCost(IInputKey supplierKey) {
		var variable = (constraint as TypeConstraint).getVariablesTuple().get(0) as PVariable
		if (boundVariables.contains(variable)) {
			cost = 0.9f
		} else {
			//cost = runtimeContext.countTuples(supplierKey, null)
			cost = DEFAULT_COST
		}
	}

	protected override dispatch void calculateCost(ExportedParameter exportedParam) {
		cost = MAX_COST+100;
	}

	/**
	 * Default cost calculation strategy
	 */
	protected override dispatch void calculateCost(PConstraint constraint) {
		if (freeVariables.isEmpty) {
			cost = 1.0f;
		} else {
			cost = DEFAULT_COST
		}
	}
	
}