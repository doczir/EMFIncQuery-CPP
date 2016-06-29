package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.collect.ImmutableSet
import com.google.common.collect.Iterables
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Set
import java.util.concurrent.atomic.AtomicInteger
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.PAnnotation
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PDisjunction
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener
import java.util.Collection

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
		
		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		val normalizedBodies = normalizedDisjunction.bodies.toList
		
		val bindings = pQuery.allAnnotations.filter[name == "Bind"]
		val boundPatternStubs = bindings.map[ binding |
			val boundParameters = getBoundParameters(binding, pQuery) 

			val bodies = normalizedBodies.compile(boundParameters, frameRegistry)
			return new PatternStub(pQuery, bodies, boundParameters)
		]

		val bodies  = if(normalizedDisjunction.sensibleWithoutBinding) {
			normalizedBodies.compile(#{}, frameRegistry)
		} else {
			#{}
		}
		val unboundPatternStub = new PatternStub(pQuery, bodies)
		// copy to prevent lazy evaluation
		return ImmutableSet::copyOf(Iterables::concat(#[unboundPatternStub], boundPatternStubs))
	}
	
	private def getBoundParameters(PAnnotation binding, PQuery pQuery) {
		binding.getAllValues("parameters").map [
			switch (it) {
				ParameterReference: #[it]
				List<ParameterReference>: it
			}
		].flatten.map[
			pQuery.parameters.get(pQuery.getPositionOfParameter(it.name))
		].toSet
	}

	def compile(List<PBody> normalizedBodies, Iterable<PParameter> boundParameters, MatchingFrameRegistry frameRegistry) {

		val AtomicInteger counter = new AtomicInteger(0)
		val patternBodyStubs = normalizedBodies.map[pBody |
			val boundPVariables = boundParameters.map[pBody.getVariableByNameChecked(name)]
												 .toSet

			val acceptor = new CPPSearchOperationAcceptor(counter.getAndIncrement, frameRegistry)
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