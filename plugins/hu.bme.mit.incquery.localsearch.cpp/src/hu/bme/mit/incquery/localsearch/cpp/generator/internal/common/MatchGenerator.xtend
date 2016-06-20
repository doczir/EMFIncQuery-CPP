package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import java.util.List
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

class MatchGenerator extends ViatraQueryHeaderGenerator {

	val String queryName
	val String patternName
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	val List<PVariable> keyVariables
	

	new(String queryName, String patternName, MatchingFrameStub matchingFrame) {
		super(#{queryName}, '''«patternName.toFirstUpper»Match''')
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame

		this.keyVariables = matchingFrame.keyVariables.sortBy[name].unmodifiableView
	}

	override initialize() {
		includes += matchingFrame.allTypes.map[strictType].map[
			switch it {
				EClass: Include::fromEClass(it)
				EDataType: if(it.name.toLowerCase.contains("string")) new Include("string", true)
				default: null
			}
		].filterNull
	}

	override compileInner() '''		
		struct «unitName» {
			
			«fields(keyVariables)»
			
			«equals(keyVariables)»
			
		};		
	'''
	
	override compileOuter() '''
		«hash(keyVariables)»
	'''
	
	def getMatchName() {
		return unitName
	}
	
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
		bool operator==(const «unitName»& other) const {
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

}