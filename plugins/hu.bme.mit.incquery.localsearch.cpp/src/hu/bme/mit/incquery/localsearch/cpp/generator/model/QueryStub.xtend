package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.xtend.lib.annotations.Accessors

class QueryStub {

	@Accessors(PUBLIC_GETTER)
	val String name

	val Set<PatternStub> patterns
	val Set<EClass> classes

	new(String name, Set<PatternStub> patterns, Set<EClass> classes) {
		this.name = name

		this.patterns = patterns
		this.classes = classes
	}

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