package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatcherGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Map
import java.util.Set
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include

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
	
	override initialize() {
		super.initialize
		includes += new Include("Viatra/Query/Util/IsNull.h")
		includes += new Include("type_traits", true)
	}
	
	override protected compilePlanExecution(PatternStub pattern, PatternBodyStub patternBody) '''
		auto _classHelper = &_context->get_class_helper();
		
		«assignParamsToVariables(pattern)»
		
		«val sog = searchOperations.get(pattern).get(patternBody)»
		«sog.matchFoundHandler = ['''matches.insert(«it»);''']»
		
		«val setupCode = new StringBuilder»
		«val executionCode = sog.compile(setupCode)»
		
		«setupCode.toString»
		
		«executionCode»
	'''
	
	def assignParamsToVariables(PatternStub pattern) {
		val matchingFrame = pattern.patternBodies.head.matchingFrame
		'''
		«FOR param : pattern.boundParameters»
		«val varName = NameUtils::getPurgedName(param.toPVariable(matchingFrame))»
		«IF varName != param.name»
			auto «NameUtils::getPurgedName(param.toPVariable(matchingFrame))» = «param.name»;
		«ENDIF»
		«ENDFOR»
		'''
	}
	
	
	
}