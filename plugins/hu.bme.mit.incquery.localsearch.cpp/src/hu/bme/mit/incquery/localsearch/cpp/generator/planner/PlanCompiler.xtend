package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.collect.ImmutableSet
import com.google.common.collect.Iterables
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import java.util.concurrent.atomic.AtomicInteger
import org.apache.log4j.Logger
import org.eclipse.viatra.query.runtime.emf.EMFQueryMetaContext
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.PAnnotation
import org.eclipse.viatra.query.runtime.matchers.psystem.annotations.ParameterReference
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.DefaultFlattenCallPredicate
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PBodyNormalizer
import org.eclipse.viatra.query.runtime.matchers.psystem.rewriters.PQueryFlattener

class PlanCompiler {
	
	val PQueryFlattener flattener
	val PBodyNormalizer normalizer
	val Map<PQuery, Set<String>> alreadyCompiled
	val Set<MatcherReference> dependencies
	val MatchingFrameRegistry frameRegistry
	
	extension val CPPLocalSearchRuntimeBasedStrategy strategy
	extension val POperationCompilerExperimental compiler
	
	new () {
		this.flattener = new PQueryFlattener(new DefaultFlattenCallPredicate)
		this.normalizer = new PBodyNormalizer(null, false)
		this.alreadyCompiled = newHashMap
		this.dependencies = newHashSet
		this.frameRegistry = new MatchingFrameRegistry
		
		
		this.strategy = new CPPLocalSearchRuntimeBasedStrategy(false)
		this.compiler = new POperationCompilerExperimental
	}
	
	def compilePlan(PQuery pQuery) {
		this.dependencies.clear		
		
		val normalizedBodies = pQuery.flattenAndNormalize
		
		val bindings = pQuery.allAnnotations.filter[name == "Bind"]
		val boundPatternStubs = bindings.map[ binding |
			val boundParameters = getBoundParameters(binding, pQuery)

			val bodies = normalizedBodies.compile(boundParameters, frameRegistry)
			alreadyCompiled.put(pQuery, boundParameters.map[name].toSet)
			return new PatternStub(pQuery, bodies, boundParameters)
		]

		val bodies = normalizedBodies.compile(#{}, frameRegistry)
		val unboundPatternStub = new PatternStub(pQuery, bodies)
		
		val dependentPatternStubs = dependencies.filter[
				// if not already compiled
				!alreadyCompiled.get(it.referredQuery)?.equals(it.adornment.map[name].toSet)
			].map[
				val dependentNormalizedBodies = it.referredQuery.flattenAndNormalize
				val dependentBodies = dependentNormalizedBodies.compile(it.adornment, frameRegistry)
				return new PatternStub(it.referredQuery, dependentBodies, it.adornment)
			]
		
		// copy to prevent lazy evaluation
		return ImmutableSet::copyOf(Iterables::concat(#[unboundPatternStub], boundPatternStubs, dependentPatternStubs))
	}
	
	private def flattenAndNormalize(PQuery pQuery) {
		val flatDisjunction = flattener.rewrite(pQuery.disjunctBodies)
		val normalizedDisjunction = normalizer.rewrite(flatDisjunction)
		
		return normalizedDisjunction.bodies.toList
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

		// no need for atomic, required a simple counter with final reference in closure
		val AtomicInteger counter = new AtomicInteger(0)
		val patternBodyStubs = normalizedBodies.map[pBody |
			val boundPVariables = boundParameters.map[pBody.getVariableByNameChecked(name)]
												 .toSet

			val acceptor = new CPPSearchOperationAcceptor(counter.getAndIncrement, frameRegistry)
			pBody.plan(Logger::getLogger(PlanCompiler), boundPVariables, EMFQueryMetaContext.INSTANCE, null, #{})
				 .compile(pBody, boundPVariables, acceptor)
			dependencies += acceptor.dependencies
			return acceptor.patternBodyStub
		].toSet
		
		return patternBodyStubs
	}
}