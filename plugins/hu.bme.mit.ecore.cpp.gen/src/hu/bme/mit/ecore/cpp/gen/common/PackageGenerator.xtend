package hu.bme.mit.ecore.cpp.gen.common

import com.google.common.base.Joiner
import hu.bme.mit.cpp.util.fs.FileSystemAccess
import hu.bme.mit.cpp.util.util.CppHelper
import hu.bme.mit.cpp.util.util.NamespaceHelper
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EPackage

import static extension hu.bme.mit.cpp.util.fs.PathUtils.*

class PackageGenerator {
	static def void generatePackage(EPackage pack, FileSystemAccess fsa) {
		if (pack.eContents.exists[it instanceof EClass]) {
			fsa.generateFile(pack.name.definition, pack.compileDef)
			fsa.generateFile(pack.name.declaration, pack.compileDecl)
		}
	}

	private static def compileDef(EPackage pack) '''
		«val guard = CppHelper::getGuardHelper(
			Joiner.on('_').join(NamespaceHelper::getNamespaceHelper(pack)) + '_' + pack.name + "_DEF")»
		«guard.start»
		
		«FOR clazz : pack.eContents.filter(EClass)»
			#include "«NamespaceHelper::getNamespaceHelper(clazz).toString("/")»/«clazz.name».h"
		«ENDFOR»
		
		«guard.end»
	'''

	private static def compileDecl(EPackage pack) '''
		«val guard = CppHelper::getGuardHelper(
			Joiner.on('_').join(NamespaceHelper::getNamespaceHelper(pack)) + '_' + pack.name + "_DECL")»
		«guard.start»
		
		«val ns = NamespaceHelper::getNamespaceHelper(pack)»
		«FOR namespace : ns»
			namespace «namespace» {
		«ENDFOR»
		namespace «pack.name» {
		
		«FOR clazz : pack.eContents.filter(EClass)»
			class «clazz.name»;
		«ENDFOR»
		
		} /* namespace «pack.name» */
		«FOR namespace : ns»
			} /* namespace «namespace» */
		«ENDFOR»
		
		«guard.end»
	'''

}
