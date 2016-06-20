package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator

class MatcherGenerator extends ViatraQueryHeaderGenerator {
	
	val String name
	val List<PatternStub> patterns
	val MatchingFrameStub matchingFrame
	val MatchingFrameGenerator frameGen
	val MatchGenerator matchGen
	
	QuerySpecificationGenerator querySpec

	new(String patternName, List<PatternStub> patterns, MatchingFrameGenerator frameGen, MatchGenerator matchGen, QuerySpecificationGenerator querySpec) {
		super(#{patternName}, '''«patternName.toFirstUpper»Matcher''')
		this.name = patternName.toFirstUpper
		this.patterns = patterns
		this.matchingFrame = frameGen.matchingFrame
		this.frameGen = frameGen
		this.matchGen = matchGen
		this.querySpec = querySpec
	}
	
	override initialize() {
		includes += frameGen.include
		includes += matchGen.include
		includes += querySpec.include
		
		includes += new Include("Viatra/Query/QueryEngine.h")
		includes += new Include("Viatra/Query/Plan/SearchPlanExecutor.h")
		includes += new Include("unordered_set", true)
	}
	
	override compileInner() '''
		template<class ModelRoot>
		class «unitName» {
		public:
			friend class ::Viatra::Query::QueryEngine<ModelRoot>;
		
			«FOR pattern : patterns»
				«compileGetter(pattern)»
			«ENDFOR»
		
		private:
			SchoolMatcher(const ModelRoot* model, const ::Viatra::Query::Matcher::ISearchContext* context) 
				: _model(model), _context(context) {
			}
		
			const ModelRoot* _model;
			const ::Viatra::Query::Matcher::ISearchContext* _context;
		};
	'''
	
	private def compileGetter(PatternStub pattern) '''
		std::unordered_set<«name»Match> matches(«getParamList(pattern)») const {
			using ::Viatra::Query::Matcher::ISearchContext;
			using ::Viatra::Query::Plan::SearchPlan;
			using ::Viatra::Query::Plan::SearchPlanExecutor;
			using ::Viatra::Query::Matcher::ClassHelper;
		
			std::unordered_set<«name»Match> matches;
		
			auto sp = «name»QuerySpec<ModelRoot>::get_plan_«NameUtils::getPlanName(pattern)»(_model);
			
			SearchPlanExecutor<«name»Frame> exec(sp, *_context);
		
			for (auto&& frame : exec) {
				«name»Match match;
				
				«fillMatch»
				
				matches.insert(match);
			}
		
			return matches;
		}
	'''
	
	private def fillMatch() '''
		«FOR keyVariable : matchingFrame.keyVariables»
			match.«keyVariable.name» = static_cast<«keyVariable.type»>(frame._«matchingFrame.getVariablePosition(keyVariable)»)
		«ENDFOR»
	'''
	
	private def getParamList(PatternStub pattern) {
		pattern.boundVariables.map['''«it.type» «it.name»'''].join(", ")		
	}
	
	private def toTypeName(EClassifier clazz) {
		NameUtils::toTypeName(clazz)		
	}
	
	private def type(PVariable variable) {
		matchingFrame.getVariableStrictType(variable).toTypeName
	}
}