package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.List
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*

class PatternBodyStub {
	
	val PBody pBody
	
	@Accessors var MatchingFrameStub matchingFrame
	val List<SearchOperationStub> searchOperations
	
	
	new(PBody pBody) {
		checkNotNull(pBody)
		
		this.pBody = pBody
		this.searchOperations = newArrayList
	}
	
	def void addSearchOperation(SearchOperationStub searchOperation) {
		checkNotNull(searchOperation)
		
		searchOperations += searchOperation
	}

	def getSearchOperations() {
		return searchOperations.unmodifiableView
	}
	
	override toString() '''
		«FOR so : searchOperations»
			«so»
		«ENDFOR»
	'''
	
}