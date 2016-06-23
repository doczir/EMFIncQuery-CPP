package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternBodyStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Set
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.viatra.query.runtime.matchers.psystem.PVariable
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import com.ibm.icu.text.DateTimePatternGenerator.PatternInfo

abstract class MatcherGenerator extends ViatraQueryHeaderGenerator {
	
	protected val String name
	protected val Set<PatternStub> patternGroup
	protected val MatchGenerator matchGenerator
	
	protected val QuerySpecificationGenerator querySpecification

	new(String queryName, String patternName, Set<PatternStub> patternGroup, MatchGenerator matchGenerator, QuerySpecificationGenerator querySpecification) {
		super(#{queryName}, '''«patternName.toFirstUpper»Matcher''')
		this.name = patternName.toFirstUpper
		this.patternGroup = patternGroup
		this.matchGenerator = matchGenerator
		this.querySpecification = querySpecification
	}
	
	override initialize() {
		includes += matchGenerator.include
		includes += querySpecification.include
		
		includes += new Include("Viatra/Query/QueryEngine.h")
		includes += new Include("unordered_set", true)
	}
	
	override compileInner() '''
		template<class ModelRoot>
		class «unitName» {
		public:
			friend class ::Viatra::Query::QueryEngine<ModelRoot>;
		
			«FOR pattern : patternGroup»
				«compileGetter(pattern)»
			«ENDFOR»
		
		private:
			«unitName»(const ModelRoot* model, const ::Viatra::Query::Matcher::ISearchContext* context) 
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
					«compilePlanExecution(pattern, patternBody, bodyNum)»
				}
				
				«val youShallNotPrint = bodyNum++»
			«ENDFOR»
		
			return matches;
		}
	'''
	
	protected abstract def String compilePlanExecution(PatternStub pattern, PatternBodyStub patternBody, int bodyNum)
	
	protected def fillMatch(MatchingFrameStub matchingFrame) '''
		«FOR keyVariable : matchingFrame.keyVariables»
			match.«keyVariable.name» = static_cast<«keyVariable.type(matchingFrame)»>(frame._«matchingFrame.getVariablePosition(keyVariable)»);
		«ENDFOR»
	'''
	
	private def getParamList(PatternStub pattern) {
		val matchingFrame = pattern.patternBodies.head.matchingFrame
		pattern.boundParameters.map[
			toPVariable(pattern.patternBodies.head)
		].map['''«it.type(matchingFrame)» «it.name»'''].join(", ")		
	}
	
	private def toTypeName(EClassifier clazz) {
		NameUtils::toTypeName(clazz)		
	}
	
	private def type(PVariable variable, MatchingFrameStub matchingFrame) {
		matchingFrame.getVariableStrictType(variable).toTypeName
	}
	
	protected def toPVariable(PParameter pParameter, PatternBodyStub patternBody) {
		// TODO: soooo slow....
		patternBody.PBody.symbolicParameters.findFirst[it.parameterName == pParameter.name].parameterVariable
	}
}
