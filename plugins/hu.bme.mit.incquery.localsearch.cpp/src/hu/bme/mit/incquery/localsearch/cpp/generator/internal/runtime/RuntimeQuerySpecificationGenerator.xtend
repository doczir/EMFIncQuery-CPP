package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import hu.bme.mit.incquery.localsearch.cpp.generator.model.DependentSearchOperationStub
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include

class RuntimeQuerySpecificationGenerator extends QuerySpecificationGenerator {
	
	val Map<PatternStub, Map<PatternBodyStub, List<RuntimeSearchOperationGenerator>>> searchOperations
	val Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators
	
	new(String queryName, Set<PatternStub> patternGroup, Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators) {
		super(queryName, patternGroup)
		
		this.searchOperations = Maps::asMap(patternGroup)[pattern |
			Maps::asMap(pattern.patternBodies) [patternBody|
				patternBody.searchOperations.map[op |
					new RuntimeSearchOperationGenerator(queryName, op, frameGenerators.get(patternBody))
				]
			]
		]
		this.frameGenerators = frameGenerators
	}
	
	override initialize() {
		super.initialize
		includes += frameGenerators.values.map[include]
		// TODO: this does not work with if there are multiple query files, somehow the related matcher generator needs to be accessed and its include path should be used
		searchOperations.keySet
			.map[it.patternBodies]
			.flatten
			.map[it.searchOperations]
			.flatten
			.filter(DependentSearchOperationStub)
			.map[it.dependencies]
			.flatten
			.forEach[
				val matcherName = '''«it.referredQuery.fullyQualifiedName.substring(it.referredQuery.fullyQualifiedName.lastIndexOf('.')+1).toFirstUpper»Matcher'''
				includes += new Include('''«implementationNamespace.toString("/")»/«matcherName».h''')
			]
	}
	
	override generatePlan(PatternStub pattern, PatternBodyStub patternBody) '''
		«val bodyNum = patternBody.index»
		«val frame = frameGenerators.get(patternBody)»
		static ::Viatra::Query::Plan::SearchPlan<«frame.frameName»> get_plan_«NameUtils::getPlanName(pattern)»__«bodyNum»(const ModelRoot* model) {
			using namespace ::Viatra::Query::Operations::Check;
			using namespace ::Viatra::Query::Operations::Extend;
		
			::Viatra::Query::Plan::SearchPlan<«frame.frameName»> sp;
			«val setupCode = new StringBuilder»
			«val opCodes = searchOperations.get(pattern).get(patternBody).map[compile(setupCode)]»
			««« evaluate so setup code gets calculated 
			«opCodes.forEach[]»
			
			«setupCode.toString»
			
			«FOR op : opCodes»
				sp.add_operation(«op»);
			«ENDFOR»
			
			return sp;
		}
	'''
	
		
}
