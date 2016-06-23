package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import com.google.common.collect.Maps
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.MatchingFrameGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime.RuntimeSearchOperationGenerator

abstract class QuerySpecificationGenerator extends ViatraQueryHeaderGenerator {
	
	protected val Set<PatternStub> patternGroup
	protected val Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators
	protected val String queryName

	protected val String patternName
	protected val String querySpecificationName
	protected val Map<PatternStub, Map<PatternBodyStub, List<RuntimeSearchOperationGenerator>>> searchOperations
	
	
	new(String queryName, Set<PatternStub> patternGroup, Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators) {
		super(#{queryName.toFirstUpper}, '''«patternGroup.head.name.toFirstUpper»QuerySpecification''')
		this.patternGroup = patternGroup
		this.frameGenerators = frameGenerators
		this.queryName = queryName.toFirstUpper
		
		this.patternName = patternGroup.head.name.toFirstUpper
		this.querySpecificationName = '''«patternName.toFirstUpper»QuerySpecification'''
		this.searchOperations = Maps::asMap(patternGroup)[pattern |
			Maps::asMap(pattern.patternBodies) [patternBody|
				patternBody.searchOperations.map[op |
					new RuntimeSearchOperationGenerator(op, frameGenerators.get(patternBody))
				]
			]
		]
	}
	
	override initialize() {
		includes += frameGenerators.values.map[it.include]
		includes += new Include('''Viatra/Query/«queryName»/«queryName»QueryGroup.h''')
		
		includes += new Include("Viatra/Query/Util/Optional.h")
		includes += new Include("Viatra/Query/Operations/AllOperations.h")
		includes += new Include("Viatra/Query/Plan/SearchPlan.h")
	}

	// TODO: Iterating over the bodies giving them indices makes the generated code nondeterministic........................................................................................................................................................................................... ¯\_(ツ)_/¯
	override compileInner() '''
		template<class ModelRoot>
		class «patternName»Matcher;
		
		template<class ModelRoot>
		class «unitName» {
		public:
			using Matcher = «patternName»Matcher<ModelRoot>;
		
			using QueryGroup = «queryName»QueryGroup;
		
			«FOR pattern : patternGroup»
				«var bodyNum = 0»
				«FOR body : pattern.patternBodies»
					«generatePlan(pattern, body, bodyNum)»
				«val youShallNotPrint = bodyNum++»
				«ENDFOR»
			«ENDFOR»
		
		};
	'''
	
	abstract def String generatePlan(PatternStub pattern, PatternBodyStub patternBody, int bodyNum) 
	
}
