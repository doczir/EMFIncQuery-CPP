package hu.bme.mit.incquery.localsearch.cpp.generator.planner;

import java.util.Map;
import java.util.Set;

import org.eclipse.viatra.query.runtime.matchers.context.IInputKey;
import org.eclipse.viatra.query.runtime.matchers.planning.SubPlan;
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint;
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable;

public interface ISearchOperationAcceptor {
	
	public void initialize(SubPlan plan, Map<PVariable, Integer> variableMapping, Map<PConstraint, Set<Integer>> variableBindings);
	
	public void acceptContainmentCheck(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey);
	public void acceptInstanceOfClassCheck(PVariable checkedVariable, IInputKey inputKey);
	
	public void acceptIterateOverClassInstances(PVariable location, IInputKey inputKey);
	public void acceptExtendToAssociationSource(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey);
	public void acceptExtendToAssociationTarget(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey);
}
