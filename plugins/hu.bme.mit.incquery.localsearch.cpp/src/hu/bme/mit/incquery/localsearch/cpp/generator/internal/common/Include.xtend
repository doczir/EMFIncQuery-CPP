package hu.bme.mit.incquery.localsearch.cpp.generator.internal.common

import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.IGenerator
import org.eclipse.emf.ecore.EClass
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data

@Data
class Include implements IGenerator {
	
	@Accessors(PUBLIC_GETTER)
	val boolean isExternal;
	
	private val String includePath
	private val String start;
	private val String end;
	
	new (String includePath) {
		this(includePath, false)
	}
	
	new (String includePath, boolean isExternal) {
		this.includePath = includePath
		this.isExternal = isExternal
		if(isExternal) {
			start = "<"
			end = ">"
		} else {
			start = "\""
			end = "\""
		}
	}
	
	override getFileName() {
		""	
	}
	
	override initialize() {
	}
	
	override compile() '''
		#include «start»«includePath»«end»
	'''
	
	static def fromEClass(EClass eClass) {
		return new Include(CppHelper::getIncludeHelper(eClass).toString)
	}
	
}