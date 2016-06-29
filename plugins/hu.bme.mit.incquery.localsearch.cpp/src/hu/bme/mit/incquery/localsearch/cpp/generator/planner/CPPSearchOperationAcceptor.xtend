package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import com.google.common.base.Optional
import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendInstanceOfStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendMultiNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ExtendSingleNavigationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.ISearchOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.NACOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.TypeInfo
import hu.bme.mit.incquery.localsearch.cpp.generator.model.VariableInfo
import hu.bme.mit.incquery.localsearch.cpp.generator.planner.util.CompilerHelper
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.viatra.query.runtime.emf.types.EClassTransitiveInstancesKey
import org.eclipse.viatra.query.runtime.emf.types.EStructuralFeatureInstancesKey
import org.eclipse.viatra.query.runtime.matchers.context.IInputKey
import org.eclipse.viatra.query.runtime.matchers.planning.SubPlan
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.viatra.query.runtime.matchers.psystem.PConstraint
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter

class CPPSearchOperationAcceptor implements ISearchOperationAcceptor {
	
	val MatchingFrameRegistry matchingFrameRegistry
	val List<ISearchOperationStub> searchOperations
	val List<MatcherReference> dependencies
	val int id

	var Map<PVariable, TypeInfo> typeMapping
	var Map<PVariable, Integer> variableMapping
	var PBody pBody
	var MatchingFrameStub matchingFrame	
	
	
	new (int id, MatchingFrameRegistry frameRegistry) {
		this.matchingFrameRegistry = frameRegistry
		this.searchOperations = newArrayList
		this.dependencies = newArrayList
		this.id = id
	}
	
	override initialize(SubPlan plan, Map<PVariable, Integer> variableMapping, Map<PConstraint, Set<Integer>> variableBindings) {
		this.typeMapping = CompilerHelper::createTypeMapping(plan)
		this.variableMapping = variableMapping
		this.pBody = plan.body
		this.matchingFrame = getMatchingFrame(pBody)
	}
	
	override acceptContainmentCheck(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey) {
		val structrualFeature = (inputKey as EStructuralFeatureInstancesKey).wrappedKey
		
		// one to one
		if(structrualFeature.upperBound == 1) 
			searchOperations += new CheckSingleNavigationStub(matchingFrame, sourceVariable, targetVariable, structrualFeature)
		else 
			searchOperations += new CheckMultiNavigationStub(matchingFrame, sourceVariable, targetVariable, structrualFeature)
	}
	
	override acceptInstanceOfClassCheck(PVariable checkedVariable, IInputKey inputKey) {
		val eClass = (inputKey as EClassTransitiveInstancesKey).wrappedKey
		
		searchOperations += new CheckInstanceOfStub(matchingFrame, checkedVariable, eClass)
	}
	
	override acceptExtendToAssociationSource(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey) {
		val structrualFeature = (inputKey as EStructuralFeatureInstancesKey).wrappedKey
		
		createNavigationOperation(sourceVariable, targetVariable, structrualFeature)
	}
	
	override acceptExtendToAssociationTarget(PVariable sourceVariable, PVariable targetVariable, IInputKey inputKey) {
		val structrualFeature = (inputKey as EStructuralFeatureInstancesKey).wrappedKey
		
		createNavigationOperation(targetVariable, sourceVariable, (structrualFeature as EReference).EOpposite)
	}

	private def createNavigationOperation(PVariable sourceVariable, PVariable targetVariable, EStructuralFeature structrualFeature) {
		// one to one
		if(structrualFeature.upperBound == 1)
			searchOperations += new ExtendSingleNavigationStub(matchingFrame, sourceVariable, targetVariable, structrualFeature)
		else
			searchOperations += new ExtendMultiNavigationStub(matchingFrame, sourceVariable, targetVariable, structrualFeature)
	}
	
	override acceptIterateOverClassInstances(PVariable location, IInputKey inputKey) {
		val eClass = (inputKey as EClassTransitiveInstancesKey).wrappedKey
		
		searchOperations += new ExtendInstanceOfStub(matchingFrame, location, eClass)
	}
	
	override acceptNACOperation(PQuery calledPQuery, Set<PVariable> boundVariables, Set<PParameter> boundParameters) {
		val matcherName = '''«calledPQuery.fullyQualifiedName.substring(calledPQuery.fullyQualifiedName.lastIndexOf('.')+1).toFirstUpper»Matcher'''
		searchOperations += new NACOperationStub(matchingFrame, matcherName, boundVariables)
		
		
		
		dependencies += new MatcherReference(calledPQuery, boundParameters)
	}
	
	def getPatternBodyStub() {
		return new PatternBodyStub(pBody, id, matchingFrame, searchOperations);
	}
	
	def getDependencies() {
		return dependencies.unmodifiableView
	}
	
	private def getMatchingFrame(PBody pBody) {
		matchingFrameRegistry.getMatchingFrame(pBody).or[
			val variableToParameterMap = Maps::uniqueIndex(pBody.pattern.parameters) [pBody.getVariableByNameChecked(it.name)]
			// don't pass this to anything else or evaluate it! (Lazy evaluation!!)
			val variableInfos = pBody.uniqueVariables.map[
				val type = typeMapping.get(it)
				if(type == null)
					return null
				return new VariableInfo(Optional::fromNullable(variableToParameterMap.get(it)), it, type, variableMapping.get(it))
			].filterNull.toList
			val frame = new MatchingFrameStub(variableInfos)
			matchingFrameRegistry.putMatchingFrame(pBody, frame)
			return frame
		]
	}
	
}