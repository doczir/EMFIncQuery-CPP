package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QueryGroupGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatcherGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List

class RuntimeGeneratorContext extends LocalsearchGeneratorOutputProvider {

	override initializeGenerators(QueryStub query) {
		val List<IGenerator> generators = newArrayList


		query.patterns.forEach [ name, patterns |
			val frameGenMap = newHashMap
			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, name)
			patterns.forEach[
				patternBodies.forEach[ patternBody, idx |
					val matchingFrameGenerator = new MatchingFrameGenerator(query.name, patternName, idx, patternBody.matchingFrame)
					frameGenMap.put(patternBody, matchingFrameGenerator)
					generators += matchingFrameGenerator
				]
			]

			// TODO: WARNING! Incredible Hack Inc! works, but ugly...
			val matchGen = new MatchGenerator(query.name, patternName, patterns.head.patternBodies.head.matchingFrame)
			generators += matchGen
//			matchGen.initialize
			
//			matcherGen.initialize
			
			val querySpec = new QuerySpecificationGenerator(query.name, patterns.toSet, frameGenMap)
			generators += querySpec
			
			val matcherGen = new MatcherGenerator(patterns.head.name, patterns, frameGenMap, matchGen, querySpec)
			generators += matcherGen
//			querySpec.initialize
		]
		
		val queryGroupGenerator = new QueryGroupGenerator(query)
		generators += queryGroupGenerator
//		queryGroupGenerator.initialize 

		generators.forEach[initialize]

		return generators

	}

}