package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import com.google.common.base.CaseFormat
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.CheckExpressionGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.QueryGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckExpressionStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List

class RuntimeGeneratorContext extends LocalsearchGeneratorOutputProvider {

	override initializeGenerators(QueryStub query) {
		val List<IGenerator> generators = newArrayList

		val frameGenerators = newHashMap
		val matchGenerators = newHashMap
		val checkExpressionGenerators = newHashMap

		query.patterns.forEach [
			val patternName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, it.name)
			val fg = new MatchingFrameGenerator(query.name, patternName, it.matchingFrame)
			generators += fg
			frameGenerators.put(it.matchingFrame, fg)
			fg.initialize

			val mg = new MatchGenerator(query.name, patternName, it.matchingFrame)
			generators += mg
			matchGenerators.put(it.matchingFrame, mg)
			mg.initialize
		]

		CheckExpressionGenerator::resetId
		query.patterns.map[searchOperations].flatten.filter(CheckExpressionStub).forEach [
			val ce = new CheckExpressionGenerator(query.name, it)
			generators += ce
			checkExpressionGenerators.put(it, ce)
			ce.initialize
		]

		val q = new QueryGenerator(query, frameGenerators, matchGenerators, //navigationHelperGenerators,
			checkExpressionGenerators)
		generators += q
		q.initialize

		return generators

	}

}