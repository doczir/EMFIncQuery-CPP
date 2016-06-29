package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatcherGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Map
import java.util.Set

class IteratorMatcherGenerator extends MatcherGenerator {
	
	val Map<PatternStub, Map<PatternBodyStub, IteratorSearchOperationGenerator>> searchOperations
	
	new(String queryName, String patternName, Set<PatternStub> patternGroup, MatchGenerator matchGenerator, QuerySpecificationGenerator querySpecification) {
		super(queryName, patternName, patternGroup, matchGenerator, querySpecification)
		this.searchOperations = Maps::asMap(patternGroup)[pattern |
			Maps::asMap(pattern.patternBodies) [patternBody|
				val sog = new IteratorSearchOperationGenerator(patternBody.searchOperations, matchGenerator)
				sog.initialize
				return sog
			]
		]
	}
	
	override protected compilePlanExecution(PatternStub pattern, PatternBodyStub patternBody) '''
		auto _classHelper = &_context->get_class_helper();
		«val sog = searchOperations.get(pattern).get(patternBody)»
		«sog.matchFoundHandler = ['''matches.insert(«it»);''']»
		
		«sog.compile»
	'''
	
	
	
}