package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

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