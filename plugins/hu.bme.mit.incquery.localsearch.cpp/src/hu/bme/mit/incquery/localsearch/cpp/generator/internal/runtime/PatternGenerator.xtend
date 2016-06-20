package hu.bme.mit.incquery.localsearch.cpp.generator.internal.runtime

import com.google.common.base.CaseFormat
import com.google.common.base.Joiner
import com.google.common.collect.ImmutableList
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.CheckExpressionStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.xtend.lib.annotations.Accessors

class PatternGenerator extends BaseGenerator {

	val PatternStub pattern
	val MatchingFrameGenerator frameGenerator
	val MatchGenerator matchGenerator

	val List<SearchOperationGenerator> searchOperations
	@Accessors(PUBLIC_GETTER) val Set<Include> includes
	
	new(PatternStub pattern, MatchingFrameGenerator frameGenerator, MatchGenerator matchGenerator,
		Map<CheckExpressionStub, CheckExpressionGenerator> checkExpressionGenerators) {
		this.pattern = pattern
		this.frameGenerator = frameGenerator
		this.matchGenerator = matchGenerator

		this.searchOperations = ImmutableList.copyOf(pattern.searchOperations.map [
			if(checkExpressionGenerators.containsKey(it)) {
				new SearchOperationGenerator(it, frameGenerator, checkExpressionGenerators.get(it))
			} else
				new SearchOperationGenerator(it, frameGenerator)
		])
		this.includes = newHashSet
	}

	override initialize() {
		includes += frameGenerator.include
		includes += matchGenerator.include
		searchOperations.filter[operation instanceof CheckExpressionStub].forEach [
			includes += it.checkExpressionGenerator.include
		]
		includes += new Include("Localsearch/Util/Optional.h")
	}

	override compile() {
		if(pattern.bound)
			compileBound
		else
			compileSimple
	}

	def compileSimple() '''
		std::unordered_set< «matchGenerator.qualifiedName»> get_all_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»() {
			using ::Localsearch::Matcher::ISearchContext;
			using ::Localsearch::Plan::SearchPlan;
			using ::Localsearch::Plan::SearchPlanExecutor;
			using «frameGenerator.qualifiedName»;
			using «matchGenerator.qualifiedName»;
			
			using namespace ::Localsearch::Operations::Check;
			using namespace ::Localsearch::Operations::Extend;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			ISearchContext isc(_classHelper);
			
			SearchPlan< «frameGenerator.frameName»> sp;
			
			«FOR so : searchOperations»
				sp.add_operation(«so.compile»);
			«ENDFOR»
			
			
			SearchPlanExecutor<«frameGenerator.frameName»> exec(sp, isc);
			SearchPlanExecutor<«frameGenerator.frameName»>::iterator it;
			«frameGenerator.frameName» frame;
			
			for(it = exec.begin(); it != exec.end(); it++) {
				«matchGenerator.matchName» match;	
				«FOR keyVariable : matchGenerator.matchingFrame.keyVariables»
					match.«keyVariable.name» = static_cast<«matchGenerator.matchingFrame.getVariableStrictType(keyVariable).toTypeName»>(frame.«frameGenerator.getParamName(matchGenerator.matchingFrame.getVariablePosition(keyVariable))»);
				«ENDFOR»
				matches.insert(match);
			}
			return matches;
		}
		
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»() {
			using ::Localsearch::Matcher::ISearchContext;
			using ::Localsearch::Plan::SearchPlan;
			using ::Localsearch::Plan::SearchPlanExecutor;
			using «frameGenerator.qualifiedName»;
			using «matchGenerator.qualifiedName»;
			using Localsearch::Util::Optional;
			
			using namespace ::Localsearch::Operations::Check;
			using namespace ::Localsearch::Operations::Extend;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			ISearchContext isc(_classHelper);
			
			SearchPlan<«frameGenerator.frameName»> sp;
			
			«FOR so : searchOperations»
				sp.add_operation(«so.compile»);
			«ENDFOR»
			
			
			SearchPlanExecutor<«frameGenerator.frameName»> exec(sp, isc);
			SearchPlanExecutor<«frameGenerator.frameName»>::iterator it;
			«frameGenerator.frameName» frame;
			
			for(it = exec.begin(); it != exec.end(); it++) {
				«matchGenerator.matchName» match;	
				«FOR keyVariable : matchGenerator.matchingFrame.keyVariables»
					match.«keyVariable.name» = static_cast<«matchGenerator.matchingFrame.getVariableStrictType(keyVariable).toTypeName»>(frame.«frameGenerator.getParamName(matchGenerator.matchingFrame.getVariablePosition(keyVariable))»);
				«ENDFOR»
				return Optional<«matchGenerator.matchName»>::of(match);
			}
			
			return Optional<«matchGenerator.matchName»>::empty();
		}
	'''

	def compileBound() '''
		«val boundVariables = pattern.boundVariables»
		std::unordered_set< «matchGenerator.qualifiedName»> get_all_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using ::Localsearch::Matcher::ISearchContext;
			using ::Localsearch::Plan::SearchPlan;
			using ::Localsearch::Plan::SearchPlanExecutor;
			using «frameGenerator.qualifiedName»;
			using «matchGenerator.qualifiedName»;
			
			using namespace ::Localsearch::Operations::Check;
			using namespace ::Localsearch::Operations::Extend;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			ISearchContext isc(_classHelper);
			
			SearchPlan<«frameGenerator.frameName»> sp;
			
			«FOR so : searchOperations»
				sp.add_operation(«so.compile»);
			«ENDFOR»
			
			
			SearchPlanExecutor<«frameGenerator.frameName»> exec(sp, isc);
			«frameGenerator.frameName» frame;
			
			«FOR boundVariable : boundVariables»
				frame.«frameGenerator.getParamName(boundVariable)» = «boundVariable.name»;
			«ENDFOR»
			
			while(exec.execute(frame)) {
				«matchGenerator.matchName» match;	
				«FOR keyVariable : matchGenerator.matchingFrame.keyVariables»
					match.«keyVariable.name» = static_cast<«matchGenerator.matchingFrame.getVariableStrictType(keyVariable).toTypeName»>(frame.«frameGenerator.getParamName(matchGenerator.matchingFrame.getVariablePosition(keyVariable))»);
				«ENDFOR»
				matches.insert(match);
			}
			
			return matches;
		}
		
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using ::Localsearch::Matcher::ISearchContext;
			using ::Localsearch::Plan::SearchPlan;
			using ::Localsearch::Plan::SearchPlanExecutor;
			using «frameGenerator.qualifiedName»;
			using «matchGenerator.qualifiedName»;
			using Localsearch::Util::Optional;
			
			using namespace ::Localsearch::Operations::Check;
			using namespace ::Localsearch::Operations::Extend;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			ISearchContext isc(_classHelper);
			
			SearchPlan<«frameGenerator.frameName»> sp;
			
			«FOR so : searchOperations»
				sp.add_operation(«so.compile»);
			«ENDFOR»
			
			
			SearchPlanExecutor<«frameGenerator.frameName»> exec(sp, isc);
			«frameGenerator.frameName» frame;
			
			«FOR boundVariable : boundVariables»
				frame.«frameGenerator.getParamName(boundVariable)» = «boundVariable.name»;
			«ENDFOR»
			
			while(exec.execute(frame)) {
				«matchGenerator.matchName» match;
				«FOR keyVariable : matchGenerator.matchingFrame.keyVariables»
					match.«keyVariable.name» = static_cast<«matchGenerator.matchingFrame.getVariableStrictType(keyVariable).toTypeName»>(frame.«frameGenerator.getParamName(matchGenerator.matchingFrame.getVariablePosition(keyVariable))»);
				«ENDFOR»
				return Optional<«matchGenerator.matchName»>::of(match);
			}
			
			return Optional<«matchGenerator.matchName»>::empty();
		}
	'''

	def getParamList() {
		val boundVariables = pattern.boundVariables
		val params = boundVariables.map['''«matchGenerator.matchingFrame.getVariableStrictType(it).toTypeName» «name»''']
		Joiner.on(", ").join(params)
	}

	def toTypeName(EClassifier type) {
		val typeHelper = CppHelper::getTypeHelper(type)
		switch type {
			EClass: '''«typeHelper.FQN»*'''
			EDataType: '''«typeHelper.FQN»'''
		}
	}
}