package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.collect.ImmutableSet
import com.google.common.collect.Iterables
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PDisjunction
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener

class PlanCompiler {
	
	val PQueryFlattener flattener
	val PBodyNormalizer normalizer	
	
	extension val CPPLocalSearchRuntimeBasedStrategy strategy
	extension val POperationCompilerExperimental compiler
	
	new () {
		this.flattener = new PQueryFlattener(new DefaultFlattenCallPredicate)
		this.normalizer = new PBodyNormalizer(null, false)
		
		this.strategy = new CPPLocalSearchRuntimeBasedStrategy(false)
		this.compiler = new POperationCompilerExperimental
	}
	
	def compilePlan(PQuery pQuery) {
		val frameRegistry = new MatchingFrameRegistry
		val bindings = pQuery.allAnnotations.filter[name == "Bind"]
		val boundPatternStubs = bindings.map[ binding |
			val boundParameters = binding.getAllValues("parameters").map [
				switch (it) {
					ParameterReference: #[it]
					List<ParameterReference>: it
				}
			].flatten.map[
				pQuery.parameters.get(pQuery.getPositionOfParameter(it.name))
			].toSet

			val bodies = pQuery.compile(boundParameters, false, frameRegistry)
			return new PatternStub(pQuery, bodies, boundParameters)
		]

		val bodies = pQuery.compile(#{}, true, frameRegistry)
		val unboundPatternStub = new PatternStub(pQuery, bodies)
		// copy to prevent lazy evaluation
		return ImmutableSet::copyOf(Iterables::concat(#[unboundPatternStub], boundPatternStubs))
	}

	def compile(PQuery pQuery, Iterable<PParameter> boundParameters, boolean checkSanity, MatchingFrameRegistry frameRegistry) {

		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		if (checkSanity && !normalizedDisjunction.sensibleWithoutBinding) 
			return #{}
		
		val normalizedBodies = normalizedDisjunction.bodies

		val patternBodyStubs = normalizedBodies.map[pBody |
			val boundPVariables = boundParameters.map[pBody.getVariableByNameChecked(name)]
												 .toSet

			val acceptor = new CPPSearchOperationAcceptor(frameRegistry)
			pBody.plan(Logger::getLogger(PlanCompiler), boundPVariables, EMFQueryMetaContext.INSTANCE, null, #{})
				 .compile(pBody, boundPVariables, acceptor)
				 
			return acceptor.patternBodyStub				 
		].toSet
		
		return patternBodyStubs
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