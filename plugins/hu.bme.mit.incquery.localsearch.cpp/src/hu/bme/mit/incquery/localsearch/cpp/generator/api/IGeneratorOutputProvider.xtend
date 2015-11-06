package hu.bme.mit.incquery.localsearch.cpp.generator.api

import java.util.List

interface IGeneratorOutputProvider {

	def List<GeneratorOutputRecord> getOutput()
	
}