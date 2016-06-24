package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.xtend.lib.annotations.Accessors

class QueryStub {

	@Accessors(PUBLIC_GETTER)
	val String name

	val Set<PatternStub> patterns
	val Set<EClass> classes

	new(String name) {
		this.name = name

		this.patterns = newHashSet
		this.classes = newHashSet
	}
	
	new(String name, Set<PatternStub> patterns, Set<EClass> classes) {
		this.name = name

		this.patterns = patterns
		this.classes = classes
	}

//	def addPattern(PQuery pQuery) {
//		addPattern(pQuery, #{})
//	}
//
//	def addPattern(PQuery pQuery, Set<PParameter> boundVariables) {
//		checkNotNull(pQuery)
//		val p = new PatternStub(pQuery, boundVariables)
//		patterns += p
//		return p
//	}
//
//	def addClasses(Set<EClass> classes) {
//		this.classes += classes
//	}

	def getPatterns() {
		patterns.groupBy[it.name].unmodifiableView
	}

	def getClasses() {
		classes.unmodifiableView
	}
	
	override toString() '''
		Query<«name»>:
			«FOR pattern : patterns»
				«pattern»
			«ENDFOR»		
	'''
	
}