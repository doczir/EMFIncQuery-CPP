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
package org.eclipse.viatra.query.localsearch.cpp.generator.model

import org.eclipse.viatra.query.localsearch.cpp.generator.planner.MatcherReference
import java.util.Set
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data

/**
 * @author Robert Doczi
 */
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
