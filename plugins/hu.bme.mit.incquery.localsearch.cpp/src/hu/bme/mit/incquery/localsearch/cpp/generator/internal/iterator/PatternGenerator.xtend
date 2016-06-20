package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import com.google.common.base.CaseFormat
import com.google.common.base.Joiner
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.PatternStub
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.xtend.lib.annotations.Accessors

class PatternGenerator extends BaseGenerator {

	val PatternStub pattern
	val MatchGenerator matchGenerator

	SearchOperationGenerator searchOperationsGenerator
	@Accessors(PUBLIC_GETTER) val Set<Include> includes

	new(PatternStub pattern, MatchGenerator matchGenerator) {
		this.pattern = pattern
		this.matchGenerator = matchGenerator

		this.searchOperationsGenerator = new SearchOperationGenerator(pattern.searchOperations, matchGenerator)
		this.includes = newHashSet
	}

	override initialize() {
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
			
			«searchOperationsGenerator.initialize()»
			«searchOperationsGenerator.matchFoundHandler = ['''matches.insert(«it»);''']»
			
			«searchOperationsGenerator.compile()»
			
			return matches;
		}

«««		get_one		
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»() {
			using Localsearch::Matcher::ISearchContext;
			using Localsearch::Util::Optional;
			using «matchGenerator.qualifiedName»;
			
			«searchOperationsGenerator.initialize()»
			«searchOperationsGenerator.matchFoundHandler = ['''return Optional<«matchGenerator.matchName»>::of(«it»);''']»
			
			«searchOperationsGenerator.compile()»
			
			return Optional<«matchGenerator.matchName»>::empty();
		}
	'''
	
	def compileBound() '''
«««		get_all
		std::unordered_set< «matchGenerator.qualifiedName»> get_all_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using Localsearch::Matcher::ISearchContext;
			using «matchGenerator.qualifiedName»;
			
			std::unordered_set<«matchGenerator.matchName»> matches;
			
			«searchOperationsGenerator.initialize()»
			«searchOperationsGenerator.matchFoundHandler = ['''matches.insert(«it»);''']»
			
			«searchOperationsGenerator.compile()»
			
			return matches;
		}
		
«««		get_one
		Localsearch::Util::Optional< «matchGenerator.qualifiedName»> get_one_«CaseFormat::LOWER_CAMEL.to(CaseFormat::LOWER_UNDERSCORE, pattern.name)»(«paramList») {
			using Localsearch::Matcher::ISearchContext;
			using Localsearch::Util::Optional;
			using «matchGenerator.qualifiedName»;
			
			«searchOperationsGenerator.initialize()»
			«searchOperationsGenerator.matchFoundHandler = ['''return Optional<«matchGenerator.matchName»>::of(«it»);''']»
			
			«searchOperationsGenerator.compile()»
			
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