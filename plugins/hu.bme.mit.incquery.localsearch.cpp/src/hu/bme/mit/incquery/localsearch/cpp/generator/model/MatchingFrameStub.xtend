package hu.bme.mit.incquery.localsearch.cpp.generator.model

import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper.TypeMap
import java.util.Comparator
import java.util.List
import java.util.Map
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable

import static com.google.common.base.Preconditions.*

class MatchingFrameStub {

	val Map<PVariable, TypeMap> variableTypeMap
	val Map<PVariable, Integer> variablePositionMap
	val List<PVariable> keyVariables

	new() {
		this.variableTypeMap = newTreeMap(Comparator::comparing[name])
		this.variablePositionMap = newTreeMap(Comparator::comparing[name])
		this.keyVariables = newArrayList
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
	
	def setVariableKey(PVariable variable) {
		checkNotNull(variable)
		keyVariables += variable
	}
	
	def getAllVariables() {
		variableTypeMap.keySet.unmodifiableView
	}
	
	def getKeyVariables() {
		keyVariables.unmodifiableView
	}
	
	def getAllTypes() {
		variableTypeMap.values.toSet.unmodifiableView
	}
}