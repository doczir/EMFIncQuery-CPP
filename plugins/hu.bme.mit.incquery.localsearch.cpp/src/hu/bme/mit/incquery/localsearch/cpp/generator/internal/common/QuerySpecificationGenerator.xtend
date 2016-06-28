package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Set

abstract class QuerySpecificationGenerator extends ViatraQueryHeaderGenerator {
	
	protected val Set<PatternStub> patternGroup
	protected val String queryName

	protected val String patternName
	protected val String querySpecificationName
	
	
	new(String queryName, Set<PatternStub> patternGroup) {
		super(#{queryName.toFirstUpper}, '''«patternGroup.head.name.toFirstUpper»QuerySpecification''')
		this.patternGroup = patternGroup
		this.queryName = queryName.toFirstUpper
		
		this.patternName = patternGroup.head.name.toFirstUpper
		this.querySpecificationName = '''«patternName.toFirstUpper»QuerySpecification'''
	}
	
	override initialize() {
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
				«FOR body : pattern.patternBodies»
					«generatePlan(pattern, body)»
				«ENDFOR»
			«ENDFOR»
		
		};
	'''
	
	abstract def String generatePlan(PatternStub pattern, PatternBodyStub patternBody) 
	
}
