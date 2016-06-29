package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.List
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*

class PatternBodyStub {
	
	@Accessors val PBody pBody
	@Accessors val MatchingFrameStub matchingFrame
	val List<ISearchOperationStub> searchOperations
	@Accessors val int index
	
	
//	new(PBody pBody) {
//		checkNotNull(pBody)
//		
//		this.pBody = pBody
//		this.searchOperations = newArrayList
//	}
	
	new(PBody pBody, int index, MatchingFrameStub matchingFrame, List<ISearchOperationStub> searchOperations) {
		checkNotNull(pBody)
		
		this.pBody = pBody
		this.matchingFrame = matchingFrame
		this.searchOperations = searchOperations
		this.index = index
	}
	
	def void addSearchOperation(ISearchOperationStub searchOperation) {
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