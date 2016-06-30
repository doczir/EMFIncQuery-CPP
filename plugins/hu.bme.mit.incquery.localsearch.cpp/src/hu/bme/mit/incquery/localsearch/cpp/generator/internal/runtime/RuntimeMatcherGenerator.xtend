package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatcherGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Map
import java.util.Set
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable

class RuntimeMatcherGenerator extends MatcherGenerator {
	
	val Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators
	
	new(String queryName, String patternName, Set<PatternStub> patternGroup, Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators, MatchGenerator matchGenerator, RuntimeQuerySpecificationGenerator querySpecification) {
		super(queryName, patternName, patternGroup, matchGenerator, querySpecification)
		this.frameGenerators = frameGenerators
	}
	
	override initialize() {
		super.initialize
		
		includes += frameGenerators.values.map[it.include]
		
		includes += new Include("Viatra/Query/Plan/SearchPlanExecutor.h")
	}
	

	override protected compilePlanExecution(PatternStub pattern, PatternBodyStub patternBody) '''
		«val frame = frameGenerators.get(patternBody)»
		«val bodyNum = frame.index»
		auto sp = «name»QuerySpecification<ModelRoot>::get_plan_«NameUtils::getPlanName(pattern)»__«bodyNum»(_model);
		«IF pattern.bound»
			«initializeFrame(frameGenerators.get(patternBody), pattern.boundParameters.map[toPVariable(patternBody.matchingFrame)].toSet, bodyNum)»
			
			auto exec = SearchPlanExecutor<«frame.frameName»>(sp, *_context).prepare(frame);
		«ELSE»							
			auto exec = SearchPlanExecutor<«frame.frameName»>(sp, *_context);
		«ENDIF»
		
		
		for (auto&& frame : exec) {
			«name»Match match;
		
			«fillMatch(patternBody.matchingFrame)»
		
			matches.insert(match);
		}
	'''
	
	private def initializeFrame(MatchingFrameGenerator matchingFrameGen, Set<PVariable> boundVariables, int bodyNum) '''
		«name»Frame_«bodyNum» frame;
		«FOR boundVar : boundVariables»
			frame.«matchingFrameGen.getVariableName(boundVar)» = «matchingFrameGen.matchingFrame.getParameterFromVariable(boundVar).get.name»;
		«ENDFOR»
	'''
}