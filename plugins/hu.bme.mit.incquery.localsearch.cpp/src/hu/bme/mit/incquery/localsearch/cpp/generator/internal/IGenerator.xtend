package hu.bme.mit.incquery.localsearch.cpp.generator.internal

interface IGenerator {
	def void initialize()

	def CharSequence compile()

	def CharSequence compile(StringBuilder setupCode)
	
	def String getFileName()
}