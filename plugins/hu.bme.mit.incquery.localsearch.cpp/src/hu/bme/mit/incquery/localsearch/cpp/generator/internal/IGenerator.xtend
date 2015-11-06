package hu.bme.mit.incquery.localsearch.cpp.generator.internal

interface IGenerator {
	def void initialize()

	def CharSequence compile()
	
	def String getFileName()
}