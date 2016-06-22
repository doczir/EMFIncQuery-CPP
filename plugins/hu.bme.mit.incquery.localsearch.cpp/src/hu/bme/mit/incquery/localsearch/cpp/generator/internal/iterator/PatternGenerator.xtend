package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import com.google.common.base.CaseFormat
import com.google.common.base.Joiner
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.List
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.xtend.lib.annotations.Accessors

class PatternGenerator extends BaseGenerator {

	val PatternStub pattern
	val MatchGenerator matchGenerator

	List<SearchOperationGenerator> searchOperationsGenerators
	@Accessors(PUBLIC_GETTER) val Set<Include> includes

	new(PatternStub pattern, MatchGenerator matchGenerator) {
		this.pattern = pattern
		this.matchGenerator = matchGenerator

		this.searchOperationsGenerators = pattern.patternBodies.map[ body |
			new SearchOperationGenerator(body.searchOperations, matchGenerator)
		].toList
		this.includes = newHashSet
	}

	override initialize() {
		searchOperationsGenerators.forEach[initialize]
		
		includes += matchGenerator.include
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
			using Localsearch::Matcher::ISearchContext;
			using «matchGenerator.qualifiedName»;
				
			std::unordered_set<«matchGenerator.matchName»> matches;
			
			«FOR sog : searchOperationsGenerators»
				«sog.matchFoundHandler = ['''matches.insert(«it»);''']»
						
				«sog.compile()»
			«ENDFOR»
			
			return matches;
		}

«««		get_one		
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»() {
			using Localsearch::Matcher::ISearchContext;
			using Localsearch::Util::Optional;
			using «matchGenerator.qualifiedName»;
			
			«FOR sog : searchOperationsGenerators»
				«sog.matchFoundHandler = ['''return Optional<«matchGenerator.matchName»>::of(«it»);''']»
						
				«sog.compile()»
			«ENDFOR»
			
			return Optional<«matchGenerator.matchName»>::empty();
		}
	'''
	
	def compileBound() '''
«««		get_all
		std::unordered_set< «matchGenerator.qualifiedName»> get_all_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using Localsearch::Matcher::ISearchContext;
			using «matchGenerator.qualifiedName»;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			
			«FOR sog : searchOperationsGenerators»
				«sog.matchFoundHandler = ['''matches.insert(«it»);''']»
						
				«sog.compile()»
			«ENDFOR»
			
			return matches;
		}
		
«««		get_one
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using Localsearch::Matcher::ISearchContext;
			using Localsearch::Util::Optional;
			using «matchGenerator.qualifiedName»;
			
			«FOR sog : searchOperationsGenerators»
				«sog.matchFoundHandler = ['''return Optional<«matchGenerator.matchName»>::of(«it»);''']»
						
				«sog.compile()»
			«ENDFOR»
			
			return Optional<«matchGenerator.matchName»>::empty();
		}
	'''
	
	def getParamList() {
		val boundVariables = pattern.boundParameters
		val params = boundVariables.map[toPVariable].map['''«matchGenerator.matchingFrame.getVariableStrictType(it).toTypeName» «name»''']
		Joiner.on(", ").join(params)
	}
	
	def toTypeName(EClassifier type) {
		val typeHelper = CppHelper::getTypeHelper(type)
		switch type {
			EClass: '''«typeHelper.FQN»*'''
			EDataType: '''«typeHelper.FQN»'''
		}
	}
	
	private def toPVariable(PParameter pParameter) {
		// TODO: soooo slow....
		matchGenerator.matchingFrame.allVariables.findFirst[it.name == pParameter.name]
	}

}