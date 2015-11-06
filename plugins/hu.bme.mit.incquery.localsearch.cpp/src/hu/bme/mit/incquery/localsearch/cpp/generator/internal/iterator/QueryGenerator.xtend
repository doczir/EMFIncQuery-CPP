package hu.bme.mit.incquery.localsearch.cpp.generator.internal.iterator

import com.google.common.collect.ImmutableList
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.BaseGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.MatchGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.MatchingFrameStub
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub
import java.util.Comparator
import java.util.List
import java.util.Map
import java.util.Set

class QueryGenerator extends BaseGenerator {

	val QueryStub query

	val List<PatternGenerator> patternGenerators
	val Set<Include> includes

	new(QueryStub query, Map<MatchingFrameStub, MatchGenerator> matchGenerators) {
		this.query = query

		this.patternGenerators = ImmutableList.copyOf(query.patterns.map [
			new PatternGenerator(it, matchGenerators.get(matchingFrame))
		])
		this.includes = newTreeSet(Comparator::comparing[includePath])
	}

	override initialize() {
		patternGenerators.forEach [
			initialize()
		]

		includes += new Include("deque", true)
		includes += new Include("algorithm", true)

		includes += new Include("Localsearch/Util/ClassHelper.h")
		includes += new Include("Localsearch/Matcher/ISearchContext.h")

		patternGenerators.map[it.includes].forEach[includes += it]

		query.classes.forEach[includes += Include::fromEClass(it)]
	}

	override compile() '''
		«val guard = CppHelper::getGuardHelper("LOCALSEARCH_" + query.name.toUpperCase)»
		«guard.start»
		
		«FOR include : includes.filter[isExternal]»
			«include.compile()»
		«ENDFOR»
				
		«FOR include : includes.filter[!isExternal]»
			«include.compile()»
		«ENDFOR»
		
		«val implementationNamespace = NamespaceHelper::getCustomHelper(#["Localsearch", query.name])»
		«FOR namespaceFragment : implementationNamespace»
			namespace «namespaceFragment» {
		«ENDFOR»
		
		«val className = query.name + "Queries"»
		class «className» {
		public:
			«className»() {
				using Localsearch::Util::ClassHelper;
				_classHelper = ClassHelper::builder()
					«FOR clazz : query.classes»
						«val supers = clazz.EAllGenericSuperTypes.map[EClassifier]»
						«val typeHelper = CppHelper::getTypeHelper(clazz)»
						.forClass(«typeHelper.FQN»::type_id)«IF !supers.empty»«FOR s : supers.map[CppHelper::getTypeHelper(it)]».setSuper(«s.FQN»::type_id)«ENDFOR»«ELSE».noSuper()«ENDIF»
					«ENDFOR»
			.build();
			}
			
			~«className»() {
			delete _classHelper;
			}
			
			«FOR patternGenerator : patternGenerators»
			«patternGenerator.compile()»
			«ENDFOR»
		private:
			Localsearch::Util::IClassHelper* _classHelper;
		};
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»		
		
		«guard.end»
	'''

	override getFileName() '''«query.name».h'''

}