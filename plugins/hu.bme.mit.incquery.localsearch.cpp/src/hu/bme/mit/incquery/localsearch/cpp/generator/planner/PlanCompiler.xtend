package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PDisjunction
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener

class PlanCompiler {
	
	
	val ViatraQueryEngine engine
	extension val CPPLocalSearchRuntimeBasedStrategy strategy
	extension val POperationCompiler compiler
	
	
	new (ViatraQueryEngine engine) {
		this.engine = engine
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
			].flatten

			pQuery.compile(queryStub, boundParameters, false)
		]

		pQuery.compile(queryStub, #{}, true)
	}

	def compile(PQuery pQuery, QueryStub queryStub, Iterable<ParameterReference> boundParameters, boolean checkSanity) {
		val flattener = new PQueryFlattener(new DefaultFlattenCallPredicate)
		val normalizer = new PBodyNormalizer(null, false)

		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		if (checkSanity && !normalizedDisjunction.sensibleWithoutBinding) 
			return
		
		val normalizedBodies = normalizedDisjunction.bodies

		val body = normalizedBodies.head // TODO: generate the other bodies
		val boundPVariables = boundParameters.map[body.getVariableByNameChecked(name)].toSet

		body.plan(Logger::getLogger(PlanCompiler), boundPVariables, EMFQueryMetaContext.INSTANCE, null, #{}).compile(pQuery, boundPVariables, engine, queryStub)
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