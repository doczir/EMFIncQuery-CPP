package hu.bme.mit.incquery.localsearch.cpp.generator.api

import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub

interface ILocalsearchGeneratorOutputProvider extends IGeneratorOutputProvider {
	
	def void initialize(QueryStub query)
	
}