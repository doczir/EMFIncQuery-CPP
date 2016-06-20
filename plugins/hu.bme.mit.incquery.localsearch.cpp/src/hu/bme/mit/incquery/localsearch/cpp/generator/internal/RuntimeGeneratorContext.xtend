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

		val frameGenerators = newHashMap
		val matchGenerators = newHashMap

		query.patterns.forEach [ name, patterns |
			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, name)
			val matchingFrame = patterns.head.matchingFrame
			val frameGen = new MatchingFrameGenerator(query.name, patternName, matchingFrame)
			generators += frameGen
			frameGenerators.put(matchingFrame, frameGen)
//			frameGen.initialize

			val matchGen = new MatchGenerator(query.name, patternName, matchingFrame)
			generators += matchGen
			matchGenerators.put(matchingFrame, matchGen)
//			matchGen.initialize
			
			val matcherGen = new MatcherGenerator(patterns.head.name, patterns, matchingFrame)
			generators += matcherGen
//			matcherGen.initialize
			
			val querySpec = new QuerySpecificationGenerator(query.name, patterns.toSet, frameGen)
			generators += querySpec
//			querySpec.initialize
		]
		
		val queryGroupGenerator = new QueryGroupGenerator(query)
		generators += queryGroupGenerator
//		queryGroupGenerator.initialize 

		generators.forEach[initialize]

		return generators

	}

}