package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.List
import java.util.Set
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*

class PatternStub {

	val PQuery query
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	val List<SearchOperationStub> searchOperations
	
	val Set<PVariable> boundVariables
	
	new(PQuery query, MatchingFrameStub matchingFrame) {
		this(query, matchingFrame, #{})
	}
	
	new(PQuery query, MatchingFrameStub matchingFrame, Set<PVariable> boundVariables) {
		checkNotNull(query)
		checkNotNull(matchingFrame)
		this.query = query
		this.matchingFrame = matchingFrame

		this.searchOperations = newArrayList		
		this.boundVariables = boundVariables
	}

	def addSearchOperation(SearchOperationStub searchOperation) {
		checkNotNull(searchOperation)
		searchOperations += searchOperation
	}

	def getSearchOperations() {
		searchOperations.unmodifiableView
	}

	def getName() {
		query.fullyQualifiedName.substring(query.fullyQualifiedName.lastIndexOf('.')+1)
	}
	
	def getBoundVariables() {
		boundVariables.unmodifiableView
	}
	
	def boolean isBound() {
		!boundVariables.empty
	}
}
