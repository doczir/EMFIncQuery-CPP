package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

class MatchingFrameGenerator extends BaseGenerator {

	val String queryName
	val String patternName
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	@Accessors(PUBLIC_GETTER) val String frameName
	val Set<Include> includes
	

	new(String queryName, String patternName, MatchingFrameStub matchingFrame) {
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame

		this.frameName = '''«patternName»Frame'''
		this.includes = newHashSet
	}

	override initialize() {
		matchingFrame.allTypes.forEach [
			switch it {
				EClass: includes += new Include(CppHelper::getIncludeHelper(it).toString)
				EDataType: if(it.name.toLowerCase.contains("string")) includes += new Include("string", true)
			}
		]
	}

	override compile() '''
		«val guard = CppHelper::getGuardHelper(("LOCALSEARCH_" + queryName + "_" + frameName).toUpperCase)»
		«guard.start»
		
		«FOR include : includes»
			«include.compile»
		«ENDFOR»
		
		«val implementationNamespace = NamespaceHelper::getCustomHelper(#["Localsearch", queryName])»
		«FOR namespaceFragment : implementationNamespace»
			namespace «namespaceFragment» {
		«ENDFOR»
		
		struct «frameName» {
			
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
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»	
		
		«guard.end»
	'''

	override getFileName() '''«frameName».h'''

	def toGetter(PVariable variable) '''«frameName»::«matchingFrame.getVariablePosition(variable).getter»'''

	def toSetter(PVariable variable) '''«frameName»::«matchingFrame.getVariablePosition(variable).setter»'''
	
	def getParamName(PVariable variable) {
		getParamName(matchingFrame.getVariablePosition(variable))
	}

	def getParamName(int position) '''_«position»'''

	private def getter(int position) '''get«position.paramName»'''

	private def setter(int position) '''set«position.paramName»'''

	def getInclude() {
		new Include('''Localsearch/«queryName»/«fileName»''')
	}
	
	def getQualifiedName() '''::Localsearch::«queryName»::«frameName»'''

}