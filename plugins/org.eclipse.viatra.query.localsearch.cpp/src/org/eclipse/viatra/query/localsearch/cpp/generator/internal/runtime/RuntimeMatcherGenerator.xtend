/*******************************************************************************
 * Copyright (c) 2014-2016 Robert Doczi, IncQuery Labs Ltd.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Robert Doczi - initial API and implementation
 *******************************************************************************/
package org.eclipse.viatra.query.localsearch.cpp.generator.internal.runtime

import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.Include
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.MatchGenerator
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.MatcherGenerator
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.NameUtils
import org.eclipse.viatra.query.localsearch.cpp.generator.model.PatternBodyStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.PatternStub
import java.util.Map
import java.util.Set
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable

/**
 * @author Robert Doczi
 */
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