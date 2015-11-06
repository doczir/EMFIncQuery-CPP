package hu.bme.mit.incquery.localsearch.cpp.generator.model

import com.google.common.collect.ImmutableList
import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.incquery.runtime.matchers.psystem.PVariable
import org.eclipse.incquery.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Accessors

import static com.google.common.base.Preconditions.*
import org.eclipse.emf.ecore.EClass

class QueryStub {

	@Accessors(PUBLIC_GETTER)
	val String name

	val List<EClass> classes
	val List<IPatternStub> patterns
	val List<MatchingFrameStub> matchingFrames

	new(String name) {
		this.name = name

		this.classes = newArrayList
		this.patterns = newArrayList
		this.matchingFrames = newArrayList
	}

	def addSimplePattern(PQuery pQuery, MatchingFrameStub matchingFrame) {
		checkNotNull(pQuery)
		checkNotNull(matchingFrame)
		val p = new SimplePatternStub(pQuery, matchingFrame)
		patterns += p
		return p
	}

	def addBoundPattern(PQuery pQuery, MatchingFrameStub matchingFrame, Set<PVariable> boundVariables) {
		checkNotNull(pQuery)
		checkNotNull(matchingFrame)
		checkArgument(!boundVariables.empty)
		val p = new BoundPatternStub(pQuery, matchingFrame, boundVariables)
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
		ImmutableList.copyOf(matchingFrames)
	}

	def getPatterns() {
		ImmutableList.copyOf(patterns)
	}

	def getClasses() {
		ImmutableList.copyOf(classes)
	}
}