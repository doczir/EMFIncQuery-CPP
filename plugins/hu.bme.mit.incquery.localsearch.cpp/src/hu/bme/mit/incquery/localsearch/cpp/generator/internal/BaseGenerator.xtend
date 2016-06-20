package hu.bme.mit.incquery.localsearch.cpp.generator.internal

import com.google.common.collect.Iterables
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.GuardHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.common.Include
import java.util.Comparator
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import com.google.common.base.CaseFormat

class BaseGenerator implements IGenerator{
	
	override initialize() {
	}
	
	override compile() {
	}
	
	override getFileName() {
	}
	
}

class ViatraQueryHeaderGenerator extends BaseGenerator {
	
	@Accessors(PROTECTED_GETTER) val Set<Include> includes
	val GuardHelper guard
	
	NamespaceHelper implementationNamespace

	protected new(Set<String> namespace, String unitName) {
		val fullNamespace = Iterables::concat(#{"Viatra", "Query"}, namespace)
		this.guard = CppHelper::getGuardHelper(
			Iterables::concat(fullNamespace, #{unitName})
				.map[CaseFormat::UPPER_CAMEL.to(CaseFormat::UPPER_UNDERSCORE, it)].join("__")
		)
		this.implementationNamespace = NamespaceHelper::getCustomHelper(fullNamespace)
		
		this.includes = newTreeSet(Comparator::comparing[includePath])
	}
	
	final def addInclude(Include include) {
		includes += include;
	}
	
	final def compileIncludes() '''
		«FOR include : includes.filter[isExternal]»
			«include.compile»
		«ENDFOR»
				
		«FOR include : includes.filter[!isExternal]»
			«include.compile»
		«ENDFOR»
	'''
	
	final override compile() '''
		«guard.start»
		
		«FOR include : includes.filter[isExternal]»
			«include.compile»
		«ENDFOR»
				
		«FOR include : includes.filter[!isExternal]»
			«include.compile»
		«ENDFOR»
		
		«FOR namespaceFragment : implementationNamespace»
			namespace «namespaceFragment» {
		«ENDFOR»
		
		«compileInner»
		
		«FOR namespaceFragment : implementationNamespace.toList.reverseView»
			} /* namespace «namespaceFragment» */
		«ENDFOR»
		
		«guard.end»
	'''
	
	def compileInner() ''''''
	def compileOuter() ''''''	
}