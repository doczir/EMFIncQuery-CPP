package hu.bme.mit.incquery.localsearch.cpp.generator

import hu.bme.mit.incquery.localsearch.cpp.generator.api.IGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.PlanCompiler
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.patternlanguage.emf.eMFPatternLanguage.PatternModel
import org.eclipse.emf.ecore.EClass

class LocalSearchCppGenerator {

	ILocalsearchGeneratorOutputProvider generator

	new(Class<? extends ILocalsearchGeneratorOutputProvider> generator) {
		this.generator = generator.newInstance
	}

	def IGeneratorOutputProvider generate(String queryFileName, Resource resource, List<PQuery> queries) {

		val patternModel = resource.contents.get(0) as PatternModel
		val classes = patternModel.importPackages.packageImport.map[it.EPackage].map[it.EClassifiers].flatten.filter(EClass).toSet

		val planCompiler = new PlanCompiler
		val patternStubs = queries.map[
			planCompiler.compilePlan(it)
		].flatten.toSet

		val queryStub = new QueryStub(queryFileName, patternStubs, classes)
		generator.initialize(queryStub)

		return generator
	}

}