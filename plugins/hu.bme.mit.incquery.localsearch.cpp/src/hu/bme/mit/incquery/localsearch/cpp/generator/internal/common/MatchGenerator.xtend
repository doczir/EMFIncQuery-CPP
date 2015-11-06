package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.IGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.xtend.lib.annotations.Accessors

class MatchGenerator implements IGenerator {

	val String queryName
	val String patternName
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	@Accessors(PUBLIC_GETTER) val String matchName
	val Set<Include> includes

	new(String queryName, String patternName, MatchingFrameStub matchingFrame) {
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame

		this.matchName = '''«patternName»Match'''
		this.includes = newHashSet
	}

	override getFileName() {
		'''«matchName».h'''
	}

	override initialize() {
		matchingFrame.allTypes.forEach [
			switch it {
				EClass: includes += Include::fromEClass(it)
				EDataType: if(it.name.toLowerCase.contains("string")) includes += new Include("string", true)
			}
		]
	}

	override compile() '''
		«val guard = CppHelper::getGuardHelper(("LOCALSEARCH_" + queryName + "_" + matchName).toUpperCase)»
		«guard.start»
		
		«FOR include : includes»
			«include.compile()»
		«ENDFOR»
		
		«val implementationNamespace = NamespaceHelper::getCustomHelper(#["Localsearch", queryName])»
		«FOR namespaceFragment : implementationNamespace»
			namespace «namespaceFragment» {
		«ENDFOR»
		
		struct «matchName» {
			
			«FOR param : matchingFrame.keyVariables.sortBy[name]»
				«val type = matchingFrame.getVariableStrictType(param)»
				«val typeHelper = CppHelper::getTypeHelper(type)»
				«IF type instanceof EClass»
					«typeHelper.FQN»* «param.name»;
				«ELSEIF type instanceof EDataType»
					«typeHelper.FQN» «param.name»; 
				«ENDIF»
			«ENDFOR»
		};
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»	
		
		«guard.end»
	'''

	def getInclude() {
		new Include('''Localsearch/«queryName»/«fileName»''')
	}

	def getQualifiedName() '''::Localsearch::«queryName»::«matchName»'''

}