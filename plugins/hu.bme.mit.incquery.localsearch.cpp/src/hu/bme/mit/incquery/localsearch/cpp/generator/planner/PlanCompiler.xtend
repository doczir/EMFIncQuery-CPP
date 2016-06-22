package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PDisjunction
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter

class PlanCompiler {
	
	
	extension val CPPLocalSearchRuntimeBasedStrategy strategy
	extension val POperationCompiler compiler
	
	
	new () {
		this.strategy = new CPPLocalSearchRuntimeBasedStrategy(false)
		this.compiler = new POperationCompiler
	}
	
	def compilePlan(PQuery pQuery, QueryStub queryStub) {
		val bindings = pQuery.allAnnotations.filter[name == "Bind"]
		bindings.forEach[ binding |
			val boundParameters = binding.getAllValues("parameters").map [
				switch (it) {
					ParameterReference: #[it]
					List<ParameterReference>: it
				}
			].flatten.map[
				pQuery.parameters.get(pQuery.getPositionOfParameter(it.name))
			].toSet

			val patternStub = queryStub.addPattern(pQuery, boundParameters)
			pQuery.compile(patternStub, boundParameters, false)
		]

		val patternStub = queryStub.addPattern(pQuery)
		pQuery.compile(patternStub, #{}, true)
	}

	def compile(PQuery pQuery, PatternStub patternStub, Iterable<PParameter> boundParameters, boolean checkSanity) {
		val flattener = new PQueryFlattener(new DefaultFlattenCallPredicate)
		val normalizer = new PBodyNormalizer(null, false)

		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		if (checkSanity && !normalizedDisjunction.sensibleWithoutBinding) 
			return
		
		val normalizedBodies = normalizedDisjunction.bodies

		normalizedBodies.forEach[pBody |
			val boundPVariables = boundParameters.map[pBody.getVariableByNameChecked(name)].toSet

			val patternBodyStub = patternStub.addPatternBody(pBody)
			pBody.plan(Logger::getLogger(PlanCompiler), boundPVariables, EMFQueryMetaContext.INSTANCE, null, #{})
				 .compile(pBody, boundPVariables, patternBodyStub)
		]
	}

	/**
	 * Check if the provided disjunction is sensible without binding. 
	 * 
	 * A disjunction is sensible if all the unbound variables are deducable.
	 */
	def isSensibleWithoutBinding(PDisjunction disjunction) {
		disjunction.bodies.forall[allVariables.filter[unique].forall[deducable]]
	}
}