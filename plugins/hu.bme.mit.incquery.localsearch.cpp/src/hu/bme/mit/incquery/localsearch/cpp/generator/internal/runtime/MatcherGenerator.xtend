package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.NameUtils
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter

class MatcherGenerator extends ViatraQueryHeaderGenerator {
	
	val String name
	val List<PatternStub> patterns
	val Map<PatternBodyStub, MatchingFrameGenerator> frameGenerators
	val MatchGenerator matchGen
	
	QuerySpecificationGenerator querySpec

	new(String patternName, List<PatternStub> patterns, Map<PatternBodyStub, MatchingFrameGenerator> frameGens, MatchGenerator matchGen, QuerySpecificationGenerator querySpec) {
		super(#{patternName}, '''«patternName.toFirstUpper»Matcher''')
		this.name = patternName.toFirstUpper
		this.patterns = patterns
		this.frameGenerators = frameGens
		this.matchGen = matchGen
		this.querySpec = querySpec
	}
	
	override initialize() {
		includes += matchGen.include
		includes += querySpec.include
		includes += frameGenerators.values.map[it.include]
		
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
		
			«var bodyNum = 0»
			«FOR patternBody : pattern.patternBodies»
				{
					auto sp = «name»QuerySpec<ModelRoot>::get_plan_«NameUtils::getPlanName(pattern)»__«bodyNum»(_model);
					«IF pattern.bound»
						«initializeFrame(frameGenerators.get(patternBody), pattern.boundParameters.map[toPVariable(patternBody.matchingFrame)].toSet)»
						
						auto exec = SearchPlanExecutor<«name»Frame_«bodyNum»>(sp, *_context).prepare(frame);
					«ELSE»							
						auto exec = SearchPlanExecutor<«name»Frame_«bodyNum»>(sp, *_context);
					«ENDIF»
					
					
					for (auto&& frame : exec) {
						«name»Match match;
					
						«fillMatch(patternBody.matchingFrame)»
					
						matches.insert(match);
					}
				}
				
				«val youShallNotPrint = bodyNum++»
			«ENDFOR»
		
			return matches;
		}
	'''
	
	private def initializeFrame(MatchingFrameGenerator matchingFrameGen, Set<PVariable> boundVariables) '''
		MatchingFrame& frame;
		«FOR boundVar : boundVariables»
			frame._«matchingFrameGen.getVariableName(boundVar)» = «boundVar.name»
		«ENDFOR»
	'''
	
	private def fillMatch(MatchingFrameStub matchingFrame) '''
		«FOR keyVariable : matchingFrame.keyVariables»
			match.«keyVariable.name» = static_cast<«keyVariable.type(matchingFrame)»>(frame._«matchingFrame.getVariablePosition(keyVariable)»)
		«ENDFOR»
	'''
	
	private def getParamList(PatternStub pattern) {
		val matchingFrame = pattern.patternBodies.head.matchingFrame
		pattern.boundParameters.map[toPVariable(matchingFrame)].map['''«it.type(matchingFrame)» «it.name»'''].join(", ")		
	}
	
	private def toTypeName(EClassifier clazz) {
		NameUtils::toTypeName(clazz)		
	}
	
	private def type(PVariable variable, MatchingFrameStub matchingFrame) {
		matchingFrame.getVariableStrictType(variable).toTypeName
	}
	
	private def toPVariable(PParameter pParameter, MatchingFrameStub matchingFrame) {
		// TODO: soooo slow....
		matchingFrame.allVariables.findFirst[it.name == pParameter.name]
	}
}