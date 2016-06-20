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
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	new(String queryName, String patternName, MatchingFrameStub matchingFrame) {
		super(#{queryName}, '''«patternName.toFirstUpper»Frame''')
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame
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
					
					«typeFQN»* «pos.paramName»;
					
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
					
					«typeFQN» «pos.paramName»;
					
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

	def toGetter(PVariable variable) '''«unitName»::«matchingFrame.getVariablePosition(variable).getter»'''

	def toSetter(PVariable variable) '''«unitName»::«matchingFrame.getVariablePosition(variable).setter»'''
	
	def getParamName(PVariable variable) {
		getParamName(matchingFrame.getVariablePosition(variable))
	}
	
	def getFrameName() {
		unitName
	}

	def getParamName(int position) '''_«position»'''

	private def getter(int position) '''get«position.paramName»'''

	private def setter(int position) '''set«position.paramName»'''

}