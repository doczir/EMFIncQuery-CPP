package hu.bme.mit.incquery.localsearch.cpp.ui

import hu.bme.mit.incquery.localsearch.cpp.generator.serializer.IFileAccessor
import java.io.File
import org.eclipse.xtext.generator.IFileSystemAccess

class XTextFileAccessor implements IFileAccessor {
	
	val IFileSystemAccess fsa
	
	new (IFileSystemAccess fsa) {
		this.fsa = fsa
	}
	
	override createFile(String folderPath, String fileName, CharSequence contents) {
		val path = '''«folderPath»«File.separator»«fileName»'''
		fsa.generateFile(path, contents)
	}
	
	override deleteFile(String folderPath, String fileName) {
		fsa.deleteFile('''«folderPath»«File.separator»«fileName»''')
	}
	
	override createFolder(String folderPath, String folderName) {
		throw new UnsupportedOperationException("XText IFileSystemAccess does not support folder creation")
	}	
	
}