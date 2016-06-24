package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import java.util.List
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter

class MatchGenerator extends ViatraQueryHeaderGenerator {

	val String queryName
	val String patternName
	@Accessors(PUBLIC_GETTER) val MatchingFrameStub matchingFrame

	new(String queryName, String patternName, MatchingFrameStub matchingFrame) {
		super(#{queryName}, '''«patternName.toFirstUpper»Match''')
		this.queryName = queryName
		this.patternName = patternName
		this.matchingFrame = matchingFrame

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
			
			«fields(matchingFrame.parameters)»
			
			«equals(matchingFrame.parameters)»
			
		};		
	'''
	
	override compileOuter() '''
		«hash(matchingFrame.parameters)»
	'''
	
	def getMatchName() {
		return unitName
	}
	
	private def fields(Iterable<PParameter> parameters) {
		'''
		«FOR parameter : parameters»
			«val type = matchingFrame.getVariableStrictType(matchingFrame.getVariableFromParameter(parameter))»
			«NameUtils::toTypeName(type)» «parameter.name»;
		«ENDFOR»
		'''
	}
	
	private def equals(Iterable<PParameter> parameters) {
		'''
		bool operator==(const «unitName»& other) const {
			return 
				«FOR variable : parameters SEPARATOR "&&"»
					«variable.toEquals»
				«ENDFOR»
			;
		}
		'''
	}
	
	private def toEquals(PParameter variable) {
		'''«variable.name» == other.«variable.name»'''
	}
	
	private def hash(Iterable<PParameter> parameters) {
		'''
		namespace std {
		
		template<> struct hash<«qualifiedName»> {
			unsigned operator()(const «qualifiedName»& match) const {
				return 
					«FOR parameter : parameters SEPARATOR '^'»
						«parameter.toHash»
					«ENDFOR»
				;
			}
		};
				
		}
		'''
	}
	
	private def toHash(PParameter variable) {
		'''std::hash<decltype(match.«variable.name»)>()(match.«variable.name»)'''
	}

}