package hu.bme.mit.incquery.localsearch.cpp.generator.model

import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*
import com.google.common.collect.Multimaps

class QueryStub {

	@Accessors(PUBLIC_GETTER)
	val String name

	val List<EClass> classes
	val List<PatternStub> patterns
	val List<MatchingFrameStub> matchingFrames

	new(String name) {
		this.name = name

		this.classes = newArrayList
		this.patterns = newArrayList
		this.matchingFrames = newArrayList
	}

	def addPattern(PQuery pQuery, MatchingFrameStub matchingFrame) {
		addPattern(pQuery, matchingFrame, #{})
	}

	def addPattern(PQuery pQuery, MatchingFrameStub matchingFrame, Set<PVariable> boundVariables) {
		checkNotNull(pQuery)
		checkNotNull(matchingFrame)
		checkArgument(!boundVariables.empty)
		val p = new PatternStub(pQuery, matchingFrame, boundVariables)
		patterns += p
		return p
	}

	def addMatchingFrame() {
		val mf = new MatchingFrameStub
		matchingFrames += mf
		return mf
	}
	
	def addMatchingFrame(MatchingFrameStub mf) {
		matchingFrames += mf
		return mf
	}

	def addClasses(Iterator<EClass> classes) {
		this.classes += classes.filterNull.toIterable
	}

	def getMatchingFrames() {
		matchingFrames.unmodifiableView
	}

	def getPatterns() {
		patterns.groupBy[name].unmodifiableView
	}

	def getClasses() {
		classes.unmodifiableView
	}
}