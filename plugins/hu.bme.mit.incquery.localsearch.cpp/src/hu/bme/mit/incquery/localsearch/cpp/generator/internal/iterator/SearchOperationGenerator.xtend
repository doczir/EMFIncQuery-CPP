package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.AbstractSearchOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckExpressionStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.SearchOperationStub
import java.util.Collection
import java.util.LinkedList
import java.util.Map
import java.util.function.Function
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.incquery.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

class SearchOperationGenerator extends BaseGenerator {

	val Collection<SearchOperationStub> operations;
	val MatchGenerator matchGenerator

	@Accessors(PUBLIC_SETTER)
	Function<CharSequence, CharSequence> matchFoundHandler

	val LinkedList<SearchOperationStub> operationsQueue
	val Map<String, String> variablePurgedNameCache
	val Map<String, String> variableNameCache
	val Map<String, Integer> variableNameCounter

	new(Collection<SearchOperationStub> operations, MatchGenerator matchGenerator) {
		this.operations = operations;
		this.matchGenerator = matchGenerator

		this.operationsQueue = newLinkedList
		this.variablePurgedNameCache = newHashMap
		this.variableNameCache = newHashMap
		this.variableNameCounter = newHashMap
	}

	override initialize() {
		operationsQueue.clear
		operationsQueue.addAll(operations)
	}

	override compile() {
		variableNameCache.clear
		variableNameCounter.clear
		compileNext
	}

	def dispatch compileOperation(CheckInstanceOfStub operation) '''
		if(_classHelper->is_super_type(«operation.variable.cppName»->get_type_id(), «operation.key.type.typeName»::type_id)) {
			«val typedVar = operation.variable.typedVariable(operation, operation.key)»
			«operation.key.type.typeName»«IF operation.key.type instanceof EClass»*«ENDIF» «operation.variable.incrementName» = «typedVar»;
			«compileNext»
		}
	'''

	def dispatch compileOperation(CheckSingleNavigationStub operation) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		if(«srcName»->«relName» == «tarName») {
			«compileNext»
		}
	'''

	def dispatch compileOperation(CheckMultiNavigationStub operation) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		auto& data = «srcName»->«relName»; 
		if(std::find(data.begin(), data.end(), «tarName») != data.end()) {
			«compileNext»
		}
	'''

	def dispatch compileOperation(CheckExpressionStub operation) '''
		if(«operation.expression.replaceVars») {
			«compileNext»
		}
	'''

	def replaceVars(CharSequence expression) {
		var expressionString = expression.toString
		val p = Pattern.compile("\\$([\\w-]*)\\$");
		val m = p.matcher(expression);
		while (m.find()) {
			val variable = m.group(1)
			expressionString = expressionString.replace('''$«variable»$''', '''«variable»''')
		}
		return expressionString
	}

	def dispatch compileOperation(ExtendInstanceOfStub operation) '''
		«val type = operation.matchingFrame.getVariableStrictType(operation.variable)»
		«val typeHelper = CppHelper::getTypeHelper(type)»
		«val varName = operation.variable.cppName»
		for(auto&& «varName» : («typeHelper.FQN»::_instances)) {
			«compileNext»
		}
	'''

	def dispatch compileOperation(ExtendSingleNavigationStub operation) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		auto «tarName» = «srcName»->«relName»;
		«compileNext»
	'''

	def dispatch compileOperation(ExtendMultiNavigationStub operation) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		for(auto&& «tarName» : «srcName»->«relName») {
			«compileNext»
		}
	'''

	def dispatch compileOperation(SearchOperationStub operation) '''
		//NYI {
			«compileNext»
		}
	'''

	def createMatch() '''
		«matchGenerator.qualifiedName» match;
		«FOR keyVar : matchGenerator.matchingFrame.keyVariables»
			«val variableType = matchGenerator.matchingFrame.getVariableStrictType(keyVar)»
			match.«keyVar.name» = «keyVar.cppName.castTo(variableType)»;
		«ENDFOR»
		
		«matchFoundHandler.apply("match")»
	'''

	def CharSequence compileNext() {
		if (!operationsQueue.isEmpty)
			operationsQueue.poll.compileOperation
		else
			createMatch
	}
	
	def getCppName(PVariable variable) {
		getCachedData(variableNameCache, variable.name) [
			variable.purgedName
		]
	}
	
	def incrementName(PVariable variable) {
		val name = variable.purgedName
		val count = getCachedData(variableNameCounter, variable.name) [
			0
		]
		val postfixedName = '''«name»_«count»'''
		variableNameCache.put(variable.name, postfixedName)
		return postfixedName
	}

	def getPurgedName(PVariable variable) {
		getCachedData(variablePurgedNameCache, variable.name) [
			generatePurgedName(variable)
		]
	}
	
	def generatePurgedName(PVariable variable) {
		val halfPurgedName = if (!variable.virtual) {
			val regexp = Pattern::compile("_<(.)>");
			val matcher = regexp.matcher(variable.name)
			if (matcher.find)
				'''_unnamed_«matcher.group(1)»'''
			else
				variable.name
		} else
			variable.name
		
		if(halfPurgedName.contains(".virtual")) {
			val tempName = '_' + variable.name.replace(".virtual{", "")
			return tempName.substring(0, tempName.length - 1)			
		}  else 
			return halfPurgedName
	}
	
	private def <Key, Value> getCachedData(Map<Key, Value> cache, Key key, (Key) => Value supplier) {
		if(!cache.containsKey(key)) {
			val value = supplier.apply(key)
			cache.put(key, value)
			return value
		}
		return cache.get(key)
	}

	private def typeName(EClassifier type) {
		CppHelper::getTypeHelper(type).FQN
	}

	private def castTo(String variable, EClassifier type) {
		'''static_cast<«type.typeName»«IF type instanceof EClass»*«ENDIF»>(«variable»)'''
	}

	private def typedVariable(PVariable variable, AbstractSearchOperationStub operation, EClassifier expectedType) {
		val varType = operation.matchingFrame.getVariableLooseType(variable)
		if (varType != expectedType) {
			variable.cppName.castTo(expectedType)
		} else {
			variable.cppName
		}
	}
	
	private dispatch def getType(EStructuralFeature key) {
		return key.EType
	}
	
	private dispatch def getType(EClassifier key) {
		return key
	}
}