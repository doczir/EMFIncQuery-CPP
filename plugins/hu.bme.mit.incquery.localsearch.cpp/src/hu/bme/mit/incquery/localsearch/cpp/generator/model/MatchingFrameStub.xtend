package hu.bme.mit.incquery.localsearch.cpp.generator.model

import com.google.common.base.Optional
import com.google.common.collect.BiMap
import com.google.common.collect.HashBiMap
import com.google.common.collect.Ordering
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper.TypeMap
import java.util.List
import java.util.Map
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter

import static com.google.common.base.Preconditions.*

class MatchingFrameStub {

	val Map<String, PParameter> parameterNameMap
	val BiMap<String, PVariable> parameterNameToVariableMap 
	val Map<PVariable, TypeMap> variableTypeMap
	val Map<PVariable, Integer> variablePositionMap
	val List<PVariable> keyVariables

	new() {
		this.parameterNameMap = newHashMap
		this.parameterNameToVariableMap = HashBiMap::create
		this.variableTypeMap = newTreeMap(Ordering.natural.onResultOf[name])
		this.variablePositionMap = newTreeMap(Ordering.natural.onResultOf[name])
		this.keyVariables = newArrayList
	}

	def mapParameterToVariable(PParameter param, PVariable variable) {
		parameterNameToVariableMap.put(param.name, variable)
		parameterNameMap.put(param.name, param)		
	}

	def addVariable(PVariable variable, TypeMap type, int position) {
		checkNotNull(variable)
		checkNotNull(type)
		variableTypeMap.put(variable, type)
		variablePositionMap.put(variable, position)
	}
	
	def getVariableStrictType(PVariable variable) {
		checkNotNull(variable)
		variableTypeMap.get(variable).strictType
	}
	
	def getVariableLooseType(PVariable variable) {
		checkNotNull(variable)
		variableTypeMap.get(variable).looseType
	}
	
	def getVariablePosition(PVariable variable) {
		checkNotNull(variable)
		variablePositionMap.get(variable)
	}
	
	def getVariableFromParameter(PParameter parameter) {
		checkNotNull(parameter)
		parameterNameToVariableMap.get(parameter.name)
	}
	
	def getParameterFromVariable(PVariable variable) {
		checkNotNull(variable)
		val name = parameterNameToVariableMap.inverse.get(variable)
		Optional::fromNullable(parameterNameMap.get(name))
	}
	
	def setVariableKey(PVariable variable) {
		checkNotNull(variable)
		keyVariables += variable
	}
	
	def getAllVariables() {
		variableTypeMap.keySet.unmodifiableView
	}
	
	def getParameters() {
		parameterNameMap.values.unmodifiableView
	}
	
	def getAllTypes() {
		variableTypeMap.values.toSet.unmodifiableView
	}
}