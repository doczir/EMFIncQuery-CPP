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

import org.eclipse.viatra.query.localsearch.cpp.util.util.CppHelper
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.Include
import org.eclipse.viatra.query.localsearch.cpp.generator.model.MatchingFrameStub
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * @author Robert Doczi
 */
class MatchingFrameGenerator extends ViatraQueryHeaderGenerator {

	val String queryName
	val String patternName
	@Accessors val MatchingFrameStub matchingFrame
	@Accessors val int index
	

	new(String queryName, String patternName, int index, MatchingFrameStub matchingFrame) {
		super(#{queryName}, '''«patternName.toFirstUpper»Frame_«index»''')
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame
		this.index = index
	}

	override initialize() {
		includes += matchingFrame.allTypes.map[looseType].map[
			switch it {
				EClass: Include::fromEClass(it)
				EDataType: if(it.name.toLowerCase.contains("string")) new Include("string", true)
				default: null
			}
		].filterNull
	}

	override compileInner() '''
		struct «unitName» {
			
			«FOR param : matchingFrame.allVariables.sortBy[matchingFrame.getVariablePosition(it)]»
				«val type = matchingFrame.getVariableLooseType(param)»
				«IF type instanceof EClass»
					«val typeFQN = CppHelper::getTypeHelper(type).FQN»
					«val pos = matchingFrame.getVariablePosition(param)»
					
					«typeFQN»* «pos.variableName»;
					
«««					static «typeFQN»* «pos.getter»(«frameName»& frame) {
«««						return frame.«pos.paramName»;
«««					}
«««					
«««					static void «pos.setter»(«frameName»& frame, «typeFQN»* value) {
«««						frame.«pos.paramName» = value;
«««					}
				«ELSEIF type instanceof EDataType»
					«val typeFQN = CppHelper::getTypeHelper(type).FQN»
					«val pos = matchingFrame.getVariablePosition(param)»
					
					«typeFQN» «pos.variableName»;
					
«««					static «typeFQN»& «pos.getter»(«frameName»& frame) {
«««						return frame.«pos.paramName»;
«««					}
«««					
«««					static void «pos.setter»(«frameName»& frame, «typeFQN» value) {
«««						frame.«pos.paramName» = value;
«««					}
				«ENDIF»
			«ENDFOR»
		};
	'''

	def getVariableName(PVariable variable) {
		getVariableName(matchingFrame.getVariablePosition(variable))
	}
	
	def getFrameName() {
		unitName
	}

	private def getVariableName(int position) '''_«position»'''

}