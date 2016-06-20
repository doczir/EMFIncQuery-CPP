package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import com.google.common.collect.Maps
import com.google.common.collect.Multimap
import com.google.common.collect.Multimaps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.SearchOperationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Collection
import java.util.Set
import org.eclipse.xtend2.lib.StringConcatenation
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator

class QuerySpecificationGenerator extends ViatraQueryHeaderGenerator {
	
	val Set<PatternStub> patternGroup
	val MatchingFrameGenerator frameGenerator
	
	val String patternName
	val Multimap<PatternStub, SearchOperationGenerator> searchOperations
	
	new(String queryName, Set<PatternStub> patternGroup, MatchingFrameGenerator frameGenerator
		) {
		super(#{queryName}, '''«patternGroup.head.name»QuerySpecification''')
		this.patternGroup = patternGroup
		this.frameGenerator = frameGenerator
		
		this.patternName = patternGroup.head.name
		val patternStubSearchOperationMap = Maps::<PatternStub, Collection<SearchOperationGenerator>>asMap(patternGroup)[pattern |
			pattern.searchOperations.map[ op |
				new SearchOperationGenerator(op, frameGenerator)
			]	
		]
		this.searchOperations = Multimaps::newMultimap(patternStubSearchOperationMap)[newArrayList] 
	}
	
	override initialize() {
		includes += frameGenerator.include
		
		includes += new Include("Localsearch/Util/Optional.h")
	}
	
	override getFileName() {
		super.getFileName()
	}
	
	override compileInner() '''
		template<class ModelRoot>
		class «patternName»QuerySpecification {
		public:
			using Matcher = «patternName»Matcher<ModelRoot>;
		
			using QueryGroup = «patternName»QueryGroup;
		
			«FOR pattern : patternGroup SEPARATOR StringConcatenation.DEFAULT_LINE_DELIMITER»
			static ::Viatra::Query::Plan::SearchPlan<«patternName»Frame> get_plan_«NameUtils::getPlanName(pattern)»(const ModelRoot* model) {
				using namespace ::Viatra::Query::Operations::Check;
				using namespace ::Viatra::Query::Operations::Extend;
			
				::Viatra::Query::Plan::SearchPlan< SchoolsFrame> sp;
			
				«FOR op : searchOperations.get(pattern)»
					sp.add_operation(«op.compile»);
				«ENDFOR»
				return sp;
			}
			«ENDFOR»
		
		};
	'''
	
}
