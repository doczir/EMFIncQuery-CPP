package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.SearchOperationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend2.lib.StringConcatenation

class QuerySpecificationGenerator extends ViatraQueryHeaderGenerator {
	
	val Set<PatternStub> patternGroup
	val MatchingFrameGenerator frameGenerator
	
	val String patternName
	val String querySpecificationName
	Map<PatternStub, List<SearchOperationGenerator>> searchOperations
	
	new(String queryName, Set<PatternStub> patternGroup, MatchingFrameGenerator frameGenerator) {
		super(#{queryName}, '''«patternGroup.head.name.toFirstUpper»QuerySpecification''')
		this.patternGroup = patternGroup
		this.frameGenerator = frameGenerator
		
		this.patternName = patternGroup.head.name.toFirstUpper
		this.querySpecificationName = '''«patternName.toUpperCase»QuerySpecification'''
		this.searchOperations = Maps::asMap(patternGroup)[pattern |
			pattern.searchOperations.map[ op |
				new SearchOperationGenerator(op, frameGenerator)
			]	
		] 
	}
	
	override initialize() {
		includes += frameGenerator.include
		
		includes += new Include("Viatra/Query/Util/Optional.h")
		includes += new Include("Viatra/Query/Operations/AllOperations.h")
		includes += new Include("Viatra/Query/Plan/SearchPlan.h")
	}
	
	override compileInner() '''
		template<class ModelRoot>
		class «unitName» {
		public:
			using Matcher = «patternName»Matcher<ModelRoot>;
		
			using QueryGroup = «patternName»QueryGroup;
		
			«FOR pattern : patternGroup SEPARATOR StringConcatenation.DEFAULT_LINE_DELIMITER»
			static ::Viatra::Query::Plan::SearchPlan<«patternName»Frame> get_plan_«NameUtils::getPlanName(pattern)»(const ModelRoot* model) {
				using namespace ::Viatra::Query::Operations::Check;
				using namespace ::Viatra::Query::Operations::Extend;
			
				::Viatra::Query::Plan::SearchPlan<«patternName»Frame> sp;
			
				«FOR op : searchOperations.get(pattern)»
					sp.add_operation(«op.compile»);
				«ENDFOR»
				return sp;
			}
			«ENDFOR»
		
		};
	'''
	
}
