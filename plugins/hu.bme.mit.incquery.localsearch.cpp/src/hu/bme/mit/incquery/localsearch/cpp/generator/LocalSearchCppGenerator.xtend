package hu.bme.mit.incquery.localsearch.cpp.generator

import hu.bme.mit.incquery.localsearch.cpp.generator.api.IGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.PlanCompiler
import java.util.List
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery

import static extension com.google.common.collect.Iterators.*

class LocalSearchCppGenerator {

	ILocalsearchGeneratorOutputProvider generator

	new(Class<? extends ILocalsearchGeneratorOutputProvider> generator) {
		this.generator = generator.newInstance
	}

	def IGeneratorOutputProvider generate(String queryFileName, ResourceSet resourceSet, List<PQuery> queries) {

		val classes = resourceSet.resources.map[allContents].concat.filter(EClass).filterNull.toSet

		val planCompiler = new PlanCompiler
		val patternStubs = queries.map[
			planCompiler.compilePlan(it)
		].flatten.toSet

		val queryStub = new QueryStub(queryFileName, patternStubs, classes)
		generator.initialize(queryStub)

		return generator
	}

}