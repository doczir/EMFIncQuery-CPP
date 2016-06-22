package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.SearchOperationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set

class QuerySpecificationGenerator extends ViatraQueryHeaderGenerator {
	
	val Set<PatternStub> patternGroup
	val Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators
	
	val String patternName
	val String querySpecificationName
	Map<PatternStub, Map<PatternBodyStub, List<SearchOperationGenerator>>> searchOperations
	
	new(String queryName, Set<PatternStub> patternGroup, Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators) {
		super(#{queryName}, '''«patternGroup.head.name.toFirstUpper»QuerySpecification''')
		this.patternGroup = patternGroup
		this.frameGenerators = frameGenerators
		
		this.patternName = patternGroup.head.name.toFirstUpper
		this.querySpecificationName = '''«patternName.toFirstUpper»QuerySpecification'''
		this.searchOperations = Maps::asMap(patternGroup)[pattern |
			Maps::asMap(pattern.patternBodies) [patternBody|
				patternBody.searchOperations.map[op |
					new SearchOperationGenerator(op, frameGenerators.get(patternBody))
				]
			]
		]
		this.searchOperations.forEach[]
	}
	
	override initialize() {
		includes += frameGenerators.values.map[it.include]
		
		includes += new Include("Viatra/Query/Util/Optional.h")
		includes += new Include("Viatra/Query/Operations/AllOperations.h")
		includes += new Include("Viatra/Query/Plan/SearchPlan.h")
	}

	// TODO: Iterating over the bodies giving them indices makes the generated code nondeterministic........................................................................................................................................................................................... ¯\_(ツ)_/¯
	override compileInner() '''
		template<class ModelRoot>
		class «unitName» {
		public:
			using Matcher = «patternName»Matcher<ModelRoot>;
		
			using QueryGroup = «qualifiedName»QueryGroup;
		
			«FOR pattern : patternGroup»
				«var bodyNum = 0»
				«FOR body : pattern.patternBodies»
				static ::Viatra::Query::Plan::SearchPlan<«patternName»Frame_«bodyNum»> get_plan_«NameUtils::getPlanName(pattern)»__«bodyNum»(const ModelRoot* model) {
					using namespace ::Viatra::Query::Operations::Check;
					using namespace ::Viatra::Query::Operations::Extend;
				
					::Viatra::Query::Plan::SearchPlan<«patternName»Frame_«bodyNum»> sp;
					«FOR op : searchOperations.get(pattern).get(body)»
						sp.add_operation(«op.compile»);
					«ENDFOR»
					return sp;
				}
				
				«val youShallNotPrint = bodyNum++»
				«ENDFOR»
			«ENDFOR»
		
		};
	'''
	
}
