package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import hu.bme.mit.incquery.localsearch.cpp.generator.api.GeneratorOutputRecord
import hu.bme.mit.incquery.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.ArrayList
import java.util.Collection

abstract class LocalsearchGeneratorOutputProvider implements ILocalsearchGeneratorOutputProvider {
	
	var QueryStub query

	var ArrayList<GeneratorOutputRecord> records
	
	override initialize(QueryStub query) {
		this.query = query

		this.records = newArrayList
	}

	override getOutput() {
		val generators = initializeGenerators(query)
		val root = "Viatra/Query"

		generators.forEach [
			records.add(new GeneratorOutputRecord('''«root»/«query.name.toFirstUpper»''', fileName, compile))
		]

		return records
	}

	def Collection<IGenerator> initializeGenerators(QueryStub query)
	
}