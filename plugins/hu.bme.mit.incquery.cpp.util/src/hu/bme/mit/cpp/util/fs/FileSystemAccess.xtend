package hu.bme.mit.cpp.util.fs

import java.nio.file.Path
import java.nio.file.Paths
import org.eclipse.xtend.lib.annotations.AccessorType
import org.eclipse.xtend.lib.annotations.Accessors

import static extension hu.bme.mit.cpp.util.fs.PathUtils.*
import static extension org.eclipse.xtend.lib.annotations.AccessorType.*

class FileSystemAccess {

	@Accessors(AccessorType.PUBLIC_GETTER)
	FileSystemTaskHandler handler

	@Accessors(AccessorType.PUBLIC_GETTER)
	Path root

	new(Path root, FileSystemTaskHandler handler) {
		this.root = root;
		this.handler = handler
	}
	
	def generateFile(Iterable<String> name, CharSequence content) {
		handler.addTask(new GenerateFileTask(Paths.get(root.toString, name), content.toString))
	}

	def generateFile(String name, CharSequence content) {
		handler.addTask(new GenerateFileTask(Paths.get(root.toString, name), content.toString))
	}

	def deleteFile(String name) {
		handler.addTask(new DeleteFileTask(Paths.get(root.toString, name)))
	}
	
	def createInSubfolder(String name) {
		new FileSystemAccess(root + name, handler)
	}
}
