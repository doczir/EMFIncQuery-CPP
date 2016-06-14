package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.List
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PDisjunction
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

class PlanCompiler {
	
	def compilePlan(PQuery pQuery, ViatraQueryEngine engine, QueryStub query) {
		val extension strategy = new CPPLocalSearchRuntimeBasedStrategy(false)
		val extension compiler = new POperationCompiler

		val bindings = pQuery.allAnnotations.filter[name == "Bind"]
		for (binding : bindings) {
			val boundVariables = binding.getAllValues("parameters").map [
				switch (it) {
					ParameterReference: #[it]
					List<ParameterReference>: it
				}
			].flatten

			pQuery.compile(engine, query, strategy, compiler, boundVariables, false)
		}

		pQuery.compile(engine, query, strategy, compiler, #{}, true)
	}

	def compile(PQuery pQuery, ViatraQueryEngine engine, QueryStub query, extension CPPLocalSearchRuntimeBasedStrategy strategy,
		extension POperationCompiler compiler, Iterable<ParameterReference> boundVariables, boolean checkSanity) {
		val flattener = new PQueryFlattener(new DefaultFlattenCallPredicate)
		val normalizer = new PBodyNormalizer(null, false)

		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		if (checkSanity && !normalizedDisjunction.sensibleWithoutBinding) 
			return
		
		val normalizedBodies = normalizedDisjunction.bodies

		val body = normalizedBodies.head // TODO: generate the other bodies
		val boundPVariables = boundVariables.map[body.getVariableByNameChecked(name)].toSet

		body.plan(Logger::getLogger(PlanCompiler), boundPVariables, EMFQueryMetaContext.INSTANCE, null, #{}).compile(pQuery, boundPVariables, engine, query)
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