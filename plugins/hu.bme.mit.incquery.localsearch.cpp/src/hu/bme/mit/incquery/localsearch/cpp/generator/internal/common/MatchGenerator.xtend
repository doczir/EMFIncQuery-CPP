package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import com.google.common.collect.ImmutableList
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.IGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
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
		includes += new Include("functional", true)
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
		
		«val keyVariables = ImmutableList.copyOf(matchingFrame.keyVariables.sortBy[name])»
		
		struct «matchName» {
			
			«fields(keyVariables)»
			
			«equals(keyVariables)»
			
		};
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»
		
		«hash(keyVariables)»
		
		«guard.end»
	'''
	
	private def fields(Iterable<PVariable> variables) {
		'''
		«FOR variable : variables»
			«val type = matchingFrame.getVariableStrictType(variable)»
			«val typeHelper = CppHelper::getTypeHelper(type)»
			«IF type instanceof EClass»
				«typeHelper.FQN»* «variable.name»;
			«ELSEIF type instanceof EDataType»
				«typeHelper.FQN» «variable.name»; 
			«ENDIF»
		«ENDFOR»
		'''
	}
	
	private def equals(Iterable<PVariable> variables) {
		'''
		bool operator==(const «matchName»& other) const {
			return 
				«FOR variable : variables SEPARATOR "&&"»
					«variable.toEquals»
				«ENDFOR»
			;
		}
		'''
	}
	
	private def toEquals(PVariable variable) {
		'''«variable.name» == other.«variable.name»'''
	}
	
	private def hash(Iterable<PVariable> variables) {
		'''
		namespace std {
		
		template<> struct hash<«qualifiedName»> {
			unsigned operator()(const «qualifiedName»& match) const {
				return 
					«FOR variable : variables SEPARATOR '^'»
						«variable.toHash»
					«ENDFOR»
				;
			}
		};
				
		}
		'''
	}
	
	private def toHash(PVariable variable) {
		'''std::hash<decltype(match.«variable.name»)>()(match.«variable.name»)'''
	}

	def getInclude() {
		new Include('''Localsearch/«queryName»/«fileName»''')
	}

	def getQualifiedName() '''::Localsearch::«queryName»::«matchName»'''

}