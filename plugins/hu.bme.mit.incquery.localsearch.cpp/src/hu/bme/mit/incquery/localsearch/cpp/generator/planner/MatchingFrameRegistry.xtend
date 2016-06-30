package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import java.util.Map
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import com.google.common.base.Optional

class MatchingFrameRegistry {
	
	Map<PBody, MatchingFrameStub> frameMap = newHashMap;
	
	def getMatchingFrame(PBody pBody) {
		return Optional::fromNullable(frameMap.get(pBody))
	}
	
	def putMatchingFrame(PBody pBody, MatchingFrameStub frameStub) {
		frameMap.put(pBody, frameStub)
	}
		
}