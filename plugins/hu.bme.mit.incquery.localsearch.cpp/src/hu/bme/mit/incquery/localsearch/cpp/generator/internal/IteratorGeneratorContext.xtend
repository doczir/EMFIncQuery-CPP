package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List

class IteratorGeneratorContext extends LocalsearchGeneratorOutputProvider {

	override initializeGenerators(QueryStub query) {
		val List<IGenerator> generators = newArrayList

//		query.patterns.forEach [name, patterns |
//			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, name.substring(name.lastIndexOf('.')+1))
//
//			val matchingFrame = patterns.forEach[]
//			val mg = new MatchGenerator(query.name, patternName, matchingFrame)
//			generators += mg
//			mg.initialize
//		]

//		val q = new QueryGenerator(query, matchGenerators)
//		generators += q
//		q.initialize

		return generators
	}

}