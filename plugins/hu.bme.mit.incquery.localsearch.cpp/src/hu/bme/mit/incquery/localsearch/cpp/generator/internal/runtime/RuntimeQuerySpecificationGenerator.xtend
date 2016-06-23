package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Map
import java.util.Set

class RuntimeQuerySpecificationGenerator extends QuerySpecificationGenerator {
	
	new(String queryName, Set<PatternStub> patternGroup, Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators) {
		super(queryName, patternGroup, frameGenerators)
	}
	
	override generatePlan(PatternStub pattern, PatternBodyStub patternBody, int bodyNum) '''
		static ::Viatra::Query::Plan::SearchPlan<«patternName»Frame_«bodyNum»> get_plan_«NameUtils::getPlanName(pattern)»__«bodyNum»(const ModelRoot* model) {
			using namespace ::Viatra::Query::Operations::Check;
			using namespace ::Viatra::Query::Operations::Extend;
		
			::Viatra::Query::Plan::SearchPlan<«patternName»Frame_«bodyNum»> sp;
			«FOR op : searchOperations.get(pattern).get(patternBody)»
				sp.add_operation(«op.compile»);
			«ENDFOR»
			return sp;
		}
	'''
	
		
}
