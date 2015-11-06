package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import com.google.common.base.CaseFormat
import com.google.common.base.Joiner
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckExpressionStub
import java.util.Set
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.xtend.lib.annotations.Accessors

class CheckExpressionGenerator extends BaseGenerator {

	static int id = 0

	val String queryName
	val CheckExpressionStub operation

	@Accessors(PUBLIC_GETTER) val String name
	val Set<Include> includes
	
	new(String queryName, CheckExpressionStub operation) {
		this.queryName = queryName
		this.operation = operation

		this.name = '''Check«id++»'''
		includes = newHashSet
	}
	
	static def resetId() {
		id = 0;
	}

	override initialize() {
		operation.variables.map[operation.matchingFrame.getVariableStrictType(it)].forEach[
			if(it instanceof EClass)
				includes += new Include(CppHelper::getIncludeHelper(it).toString)
			else if (it instanceof EDataType)
				if(it.name.toLowerCase.contains("string")) 
					includes += new Include("string", true)
		]
	}

	override compile() '''
		«val guard = CppHelper::getGuardHelper(("LOCALSEARCH_" + queryName + "_" + name).toUpperCase)»
		«guard.start»
			
		«FOR include : includes»
			«include.compile»
		«ENDFOR»
			
		«val implementationNamespace = NamespaceHelper::getCustomHelper(#["Localsearch", queryName])»
		«FOR namespaceFragment : implementationNamespace»
			namespace «namespaceFragment» {
		«ENDFOR»
			
		template<typename MatchingFrame>
		class «name»{
			«FOR variable : operation.variables»
				«val varName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, variable.name)»
				typedef «CppHelper::getTypeHelper(operation.matchingFrame.getVariableStrictType(variable)).FQN» (*«varName») (MatchingFrame&);
			«ENDFOR»
		public:
			«name»(«ctrArgumentList») :
				«initializerList»
			{ }
		
			bool operator() (MatchingFrame& frame) {
				return «operation.expression.replaceVars»;
			}
			
		private:
			«FOR variable : operation.variables»
				«val varName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, variable.name)»
				«varName» _«variable.name»;
			«ENDFOR»
		};
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»
		
		«guard.end»
	'''
	
	def replaceVars(CharSequence expression) {
		var expressionString = expression.toString
		val p = Pattern.compile("(?<=\\$)(.*?)(?=\\$)");
    	val m = p.matcher(expression);
    	while(m.find()) {
    		val variable = m.group(0)
    		expressionString = expressionString.replace('''$«variable»$''', '''_«variable»(frame)''')
    	}    
    	return expressionString	
	}
	
	def getInitializerList() {
		return Joiner.on(", ").join(operation.variables.map[
			'''_«it.name»(«it.name»)'''
		])
	}

	def getCtrArgumentList() {
		return Joiner.on(", ").join(operation.variables.map [
			val varName = CaseFormat::LOWER_CAMEL.to(CaseFormat::UPPER_CAMEL, it.name)
			return '''«varName» «it.name»''';
		])
	}

	override getFileName() '''«name».h'''
	
	def getInclude() {
		new Include('''Localsearch/«queryName»/«fileName»''')
	}
}