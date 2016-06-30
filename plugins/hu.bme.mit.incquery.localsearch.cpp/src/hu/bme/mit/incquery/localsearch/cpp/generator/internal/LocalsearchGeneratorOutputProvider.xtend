package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import hu.bme.mit.incquery.localsearch.cpp.generator.api.GeneratorOutputRecord
import hu.bme.mit.incquery.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.Collection

abstract class LocalsearchGeneratorOutputProvider implements ILocalsearchGeneratorOutputProvider {
	
	var QueryStub query

	override initialize(QueryStub query) {
		this.query = query
	}

	override getOutput() {
		val generators = initializeGenerators(query)
		val root = "Viatra/Query"

		return generators.map[
			new GeneratorOutputRecord('''«root»/«query.name.toFirstUpper»''', fileName, compile)
		].toList
	}

	def Collection<IGenerator> initializeGenerators(QueryStub query)
	
}