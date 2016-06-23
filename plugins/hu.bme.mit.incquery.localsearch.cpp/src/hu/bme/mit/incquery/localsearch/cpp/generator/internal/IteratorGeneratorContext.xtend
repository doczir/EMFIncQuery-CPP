package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QueryGroupGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator.IteratorMatcherGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator.IteratorQuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List

class IteratorGeneratorContext extends LocalsearchGeneratorOutputProvider {

	override initializeGenerators(QueryStub query) {
		val List<IGenerator> generators = newArrayList

		query.patterns.forEach [name, patterns |
			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, name.substring(name.lastIndexOf('.')+1))

			// TODO: WARNING! Incredible Hack Inc! works, but ugly...
			val matchGen = new MatchGenerator(query.name, patternName, patterns.head.patternBodies.head.matchingFrame)
			generators += matchGen
			
			val querySpec = new IteratorQuerySpecificationGenerator(query.name, patterns.toSet)
			generators += querySpec
			
			val matcherGen = new IteratorMatcherGenerator(query.name, patternName, patterns.toSet, matchGen, querySpec)
			generators += matcherGen
		]

		val queryGroupGenerator = new QueryGroupGenerator(query)
		generators += queryGroupGenerator

		generators.forEach[initialize]

		return generators
	}

}