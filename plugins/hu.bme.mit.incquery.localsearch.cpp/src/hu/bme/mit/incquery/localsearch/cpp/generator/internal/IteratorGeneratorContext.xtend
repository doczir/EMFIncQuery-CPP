package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List

class IteratorGeneratorContext extends LocalsearchGeneratorOutputProvider {

	override initializeGenerators(QueryStub query) {
		val List<IGenerator> generators = newArrayList

		val matchGenerators = newHashMap

		query.patterns.forEach [name, patterns |
			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, name.substring(name.lastIndexOf('.')+1))

			val matchingFrame = patterns.head.matchingFrame
			val mg = new MatchGenerator(query.name, patternName, matchingFrame)
			generators += mg
			matchGenerators.put(matchingFrame, mg)
			mg.initialize
		]

//		val q = new QueryGenerator(query, matchGenerators)
//		generators += q
//		q.initialize

		return generators
	}

}