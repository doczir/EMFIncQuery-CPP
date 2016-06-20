package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.ViatraQueryHeaderGenerator
import hu.bme.mit.incquery.localsearch.cpp.generator.model.QueryStub

class QueryGroupGenerator extends ViatraQueryHeaderGenerator {
		
	val QueryStub query
	
	new(QueryStub query) {
		super(#{query.name}, '''«query.name.toFirstUpper»QueryGroup''')
		this.query = query
	}
	
	override initialize() {
		
	}
	
	override compileInner() '''
		template<class ModelRoot>
		class «query.name»Matcher;
		
		class «unitName»{
		public:
			static «query.name»QueryGroup instance() {
				static «query.name»QueryGroup instance;
				return instance;
			}
		
			const ::Viatra::Query::Matcher::ISearchContext& context() const {
				return _isc;
			}
		
		private:
			«unitName»()
				: _isc{ ::Viatra::Query::Matcher::ClassHelper::builder()
							«FOR clazz : query.classes»
								«val supers = clazz.EAllGenericSuperTypes.map[EClassifier]»
								«val typeHelper = CppHelper::getTypeHelper(clazz)»
								.forClass(«typeHelper.FQN»::type_id)«IF !supers.empty»«FOR s : supers.map[CppHelper::getTypeHelper(it)]».setSuper(«s.FQN»::type_id)«ENDFOR»«ELSE».noSuper()«ENDIF»
							«ENDFOR»
							.build() } {
			}
		
			::Viatra::Query::Matcher::ISearchContext _isc;
		};
	'''
	
}