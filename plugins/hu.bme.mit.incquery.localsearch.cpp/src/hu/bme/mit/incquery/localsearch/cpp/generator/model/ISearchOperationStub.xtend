package hu.bme.mit.incquery.localsearch.cpp.generator.model

import hu.bme.mit.incquery.localsearch.cpp.generator.planner.MatcherReference
import java.util.Set
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data

interface ISearchOperationStub {
}

@Data
abstract class AbstractSearchOperationStub implements ISearchOperationStub{
	
	val MatchingFrameStub matchingFrame
	
}

@Data class InstanceOfStub extends AbstractSearchOperationStub {

	val PVariable variable

	val EClassifier key

}

@Data class SingleNavigationStub extends AbstractSearchOperationStub {

	val PVariable source
	val PVariable target

	val EStructuralFeature key
}

@Data class MultiNavigationStub extends SingleNavigationStub {

}

@Data class ExpressionStub extends AbstractSearchOperationStub {
	
	val Set<PVariable> variables
	
	val CharSequence expression
	
}

@Data class CheckInstanceOfStub extends InstanceOfStub {

	public static val String NAME = "InstanceOfCheck"

}

@Data class CheckSingleNavigationStub extends SingleNavigationStub {
	
	public static val String NAME = "SingleAssociationCheck"
	
}

@Data class CheckMultiNavigationStub extends MultiNavigationStub {
	
	public static val String NAME = "MultiAssociationCheck"
	
}

@Data abstract class DependentSearchOperationStub extends AbstractSearchOperationStub {
	
	@Accessors(NONE) val Set<MatcherReference> dependencies
	
	def getDependencies() {
		dependencies
	}
		
}

@Data class NACOperationStub extends DependentSearchOperationStub {
	
	public static val String NAME = "NACOperation"
	
	val CharSequence matcher
	val Set<PVariable> bindings
		
}

@Data class ExtendInstanceOfStub extends InstanceOfStub {

	public static val String NAME = "IterateOverInstances"

}

@Data class ExtendSingleNavigationStub extends SingleNavigationStub {
	
	public static val String NAME = "NavigateSingleAssociation"
	
}

@Data class ExtendMultiNavigationStub extends MultiNavigationStub {
	
	public static val String NAME = "NavigateMultiAssociation"
	
}

@Data class ExtendExpressionStub extends ExpressionStub {
}
