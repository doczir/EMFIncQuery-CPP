package hu.bme.mit.ecore.cpp.gen

import hu.bme.mit.cpp.util.fs.FileSystemAccess
import hu.bme.mit.cpp.util.fs.FileSystemTaskHandler
import hu.bme.mit.ecore.cpp.gen.common.PackageGenerator
import hu.bme.mit.ecore.cpp.gen.ecore.EClassGenerator
import java.nio.file.Path
import java.util.concurrent.TimeUnit
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource

import static hu.bme.mit.ecore.cpp.gen.ecore.EClassGenerator.*

class EcoreGenerator {

	MakefileGenerator mkgen

	val FileSystemTaskHandler handler
	val FileSystemAccess fsa
	val Resource ecoreModel


	new(Resource ecoreModel, Path root) {
		mkgen = new MakefileGenerator(ecoreModel)
		this.ecoreModel = ecoreModel
		handler = new FileSystemTaskHandler
		fsa = new FileSystemAccess(root, handler)
	}

	def startGeneration() {
		val fullName = ecoreModel.getURI.trimFileExtension.lastSegment
		fsa.deleteFile(fullName)
		// TODO: hack inc
		EClassGenerator::id = 0;
		ecoreModel.contents.forEach[generate(fsa.createInSubfolder(fullName))]

		mkgen.generate(fsa)

		handler.flush(3, TimeUnit.SECONDS)
	}

	def dispatch void generate(EPackage pack, FileSystemAccess fsa) {
		PackageGenerator::generatePackage(pack, fsa)
		pack.eContents.forEach[generate(fsa.createInSubfolder(pack.name))]
	}

	def dispatch void generate(EClass clazz, FileSystemAccess fsa) {
		EClassGenerator::generateClass(clazz, fsa)
	}

	def dispatch void generate(EObject obj, FileSystemAccess fsa) {
	}
}
