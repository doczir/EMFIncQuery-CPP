package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*

class QueryStub {

	@Accessors(PUBLIC_GETTER)
	val String name

	val List<EClass> classes
	val List<PatternStub> patterns

	new(String name) {
		this.name = name

		this.classes = newArrayList
		this.patterns = newArrayList
	}

	def addPattern(PQuery pQuery) {
		addPattern(pQuery, #{})
	}

	def addPattern(PQuery pQuery, Set<PParameter> boundVariables) {
		checkNotNull(pQuery)
		val p = new PatternStub(pQuery, boundVariables)
		patterns += p
		return p
	}

	def addClasses(Iterator<EClass> classes) {
		this.classes += classes.filterNull.toIterable
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