package hu.bme.mit.incquery.localsearch.cpp.generator

import hu.bme.mit.incquery.localsearch.cpp.generator.api.IGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.PlanCompiler
import java.util.List
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery

import static extension com.google.common.collect.Iterators.*
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

class LocalSearchCppGenerator {

	ILocalsearchGeneratorOutputProvider generator

	new(Class<? extends ILocalsearchGeneratorOutputProvider> generator) {
		this.generator = generator.newInstance
	}

	def IGeneratorOutputProvider generate(String queryFileName, ResourceSet resourceSet, List<PQuery> queries) {

		val engine = ViatraQueryEngine.on(new EMFScope(resourceSet))

		val query = new QueryStub(queryFileName)
		query.addClasses(resourceSet.resources.map[allContents].concat.filter(EClass))

		val planCompiler = new PlanCompiler(engine)
		queries.forEach[planCompiler.compilePlan(it, query)]

		generator.initialize(query)

		return generator
	}

}