package hu.bme.mit.incquery.localsearch.cpp.generator.model

import com.google.common.collect.ImmutableList
import com.google.common.collect.ImmutableSet
import java.util.Collection
import java.util.List
import java.util.Set
import org.eclipse.incquery.runtime.matchers.psystem.PVariable
import org.eclipse.incquery.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*

interface IPatternStub {
	def void addSearchOperation(SearchOperationStub searchOperation)

	def Collection<SearchOperationStub> getSearchOperations()
	
	def MatchingFrameStub getMatchingFrame()
	
	def String getName()
} 

class SimplePatternStub implements IPatternStub {

	val PQuery query
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	val List<SearchOperationStub> searchOperations

	new(PQuery query, MatchingFrameStub matchingFrame) {
		checkNotNull(query)
		checkNotNull(matchingFrame)
		this.query = query
		this.matchingFrame = matchingFrame

		this.searchOperations = newArrayList
	}

	override addSearchOperation(SearchOperationStub searchOperation) {
		checkNotNull(searchOperation)
		searchOperations += searchOperation
	}

	override getSearchOperations() {
		ImmutableList.copyOf(searchOperations)
	}

	override getName() {
		query.fullyQualifiedName.substring(query.fullyQualifiedName.lastIndexOf('.')+1)
	}
}

class BoundPatternStub extends SimplePatternStub {
	
	val Set<PVariable> boundVariables
	
	new(PQuery query, MatchingFrameStub matchingFrame, Set<PVariable> boundVariables) {
		super(query, matchingFrame)
		
		this.boundVariables = boundVariables
	}
	
	def getBoundVariables() {
		ImmutableSet.copyOf(boundVariables)
	}
}