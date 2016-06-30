package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Set

class IteratorQuerySpecificationGenerator extends QuerySpecificationGenerator {
	
	new(String queryName, Set<PatternStub> patternGroup) {
		super(queryName, patternGroup)
	}
	
	override generatePlan(PatternStub pattern, PatternBodyStub patternBody) ''''''
	
		
}