package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.Set
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery

import static com.google.common.base.Preconditions.*

class PatternStub {

	val PQuery query
	val Set<PParameter> boundParameters
	
	val Set<PatternBodyStub> bodies
	
	new(PQuery query, Set<PatternBodyStub> bodies) {
		this(query, bodies, #{})
	}
	
//	new(PQuery query, Set<PParameter> boundParameters) {
//		checkNotNull(query)
//		this.query = query
//
//		this.bodies = newLinkedHashSet
//		this.boundParameters = boundParameters
//	}
	
	new(PQuery query, Set<PatternBodyStub> bodies, Set<PParameter> boundParameters) {
		checkNotNull(query)
		checkNotNull(bodies)
		checkNotNull(boundParameters)	
		checkArgument(!bodies.empty)	
		
		this.query = query

		this.bodies = bodies
		this.boundParameters = boundParameters
	}

//	def addPatternBody(PBody pBody) {
//		val body = new PatternBodyStub(pBody)
//		bodies += body
//		return body
//	}

	def getPatternBodies() {
		bodies.unmodifiableView
	}

	def getName() {
		query.fullyQualifiedName.substring(query.fullyQualifiedName.lastIndexOf('.')+1)
	}
	
	def getBoundParameters() {
		boundParameters.unmodifiableView
	}
	
	def boolean isBound() {
		!boundParameters.empty
	}
	
	override toString() '''
		pattern <«name»> («paramList») «FOR body : bodies SEPARATOR " or "» {
			«body»
		} «ENDFOR»
		
	'''
	
	private def paramList() {
		val paramNames = newArrayList
		for(i : 0..<query.parameters.size) {
			val param = query.parameterNames.get(i)
			if(boundParameters.map[name].findFirst[it == query.parameters.get(i).name] != null)
				paramNames += param + " (B)"
			else 
				paramNames += param
		}
		
		paramNames.join(", ")
	}
	
}
