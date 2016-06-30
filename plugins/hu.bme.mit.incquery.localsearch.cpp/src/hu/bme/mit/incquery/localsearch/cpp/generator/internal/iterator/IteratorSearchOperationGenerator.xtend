package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.model.AbstractSearchOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ISearchOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.NACOperationStub
import java.util.Collection
import java.util.LinkedList
import java.util.Map
import java.util.function.Function
import java.util.regex.Pattern
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.xtend.lib.annotations.Accessors

class IteratorSearchOperationGenerator extends BaseGenerator {

	val Collection<ISearchOperationStub> operations;
	val MatchGenerator matchGenerator

	@Accessors(PUBLIC_SETTER)
	Function<CharSequence, CharSequence> matchFoundHandler

	val LinkedList<ISearchOperationStub> operationsQueue
	val Map<String, String> variablePurgedNameCache
	val Map<String, String> variableNameCache
	val Map<String, Integer> variableNameCounter

	new(Collection<ISearchOperationStub> operations, MatchGenerator matchGenerator) {
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

	override compile(StringBuilder setupCode) {
		variableNameCache.clear
		variableNameCounter.clear
		compileNext(setupCode)
	}

	def dispatch compileOperation(CheckInstanceOfStub operation, StringBuilder setupCode) '''
		if(_classHelper->is_super_type(«operation.variable.cppName»->get_type_id(), «operation.key.type.typeName»::type_id)) {
			«val typedVar = operation.variable.typedVariable(operation, operation.key)»
			auto «operation.variable.incrementName» = «typedVar»;
			«compileNext(setupCode)»
		}
	'''

	def dispatch compileOperation(CheckSingleNavigationStub operation, StringBuilder setupCode) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		if(«srcName»->«relName» == «tarName») {
			«compileNext(setupCode)»
		}
	'''

	def dispatch compileOperation(CheckMultiNavigationStub operation, StringBuilder setupCode) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		auto& data = «srcName»->«relName»; 
		if(std::find(data.begin(), data.end(), «tarName») != data.end()) {
			«compileNext(setupCode)»
		}
	'''
	
	def dispatch compileOperation(NACOperationStub operation, StringBuilder setupCode) '''
		«val matcherName = '''matcher_«Math.abs(operation.hashCode)»'''»
		«val youShallNotPrint = setupCode.append('''«operation.matcher»<ModelRoot> «matcherName»(_model,  _context);''')»
		if(«matcherName».matches(«operation.bindings.map[cppName].join(", ")»).size() == 0) {
			«compileNext(setupCode)»
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

	def dispatch compileOperation(ExtendInstanceOfStub operation, StringBuilder setupCode) '''
		«val type = operation.matchingFrame.getVariableStrictType(operation.variable)»
		«val typeHelper = CppHelper::getTypeHelper(type)»
		«val varName = operation.variable.cppName»
		for(auto&& «varName» : (ModelIndex<std::remove_pointer<«typeHelper.FQN»>::type, ModelRoot>::instances(_model))) {
			«compileNext(setupCode)»
		}
	'''

	def dispatch compileOperation(ExtendSingleNavigationStub operation, StringBuilder setupCode) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		if(!::Viatra::Query::Util::IsNull<decltype(«srcName»->«relName»)>::check(«srcName»->«relName»)) {
			auto «tarName» = «srcName»->«relName»;
			«compileNext(setupCode)»
		}
	'''

	def dispatch compileOperation(ExtendMultiNavigationStub operation, StringBuilder setupCode) '''
		«val tarName = operation.target.cppName»
		«val srcName = operation.source.cppName»
		«val relName = operation.key.name»
		for(auto&& «tarName» : «srcName»->«relName») {
			«compileNext(setupCode)»
		}
	'''

	def dispatch compileOperation(ISearchOperationStub operation, StringBuilder setupCode) '''
		//NYI {
			«compileNext(setupCode)»
		}
	'''

	def createMatch() '''
		«matchGenerator.qualifiedName» match;
		«FOR parameter : matchGenerator.matchingFrame.parameters»
			«val keyVariable = matchGenerator.matchingFrame.getVariableFromParameter(parameter)»
			«val variableType = matchGenerator.matchingFrame.getVariableStrictType(keyVariable)»
			match.«parameter.name» = «keyVariable.cppName.castTo(variableType)»;
		«ENDFOR»
		
		«matchFoundHandler.apply("match")»
	'''

	def CharSequence compileNext(StringBuilder setupCode) {
		if (!operationsQueue.isEmpty)
			operationsQueue.poll.compileOperation(setupCode)
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
		variableNameCounter.put(variable.name, count + 1)
		return postfixedName
	}

	def getPurgedName(PVariable variable) {
		getCachedData(variablePurgedNameCache, variable.name) [
			NameUtils::getPurgedName(variable)
		]
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