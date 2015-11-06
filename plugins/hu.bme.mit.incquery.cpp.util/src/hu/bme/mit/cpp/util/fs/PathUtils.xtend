package hu.bme.mit.cpp.util.fs

import java.nio.file.Path
import java.nio.file.Paths

class PathUtils {

	static val String SOURCE_EXT = ".cpp"
	static val String HEADER_EXT = ".h"
	
	static val String DEFINITION_HEADER_EXT = "_def.h"
	static val String DECLARATION_HEADER_EXT = "_decl.h"

	/**
	 * Appends the string to the end of the path
	 */
	static def operator_plus(Path p1, String a) {
		Paths.get(p1.toString, a);
	}

	static def h(String fileName) {
		fileName + HEADER_EXT
	}

	static def cpp(String fileName) {
		fileName + SOURCE_EXT
	}
	
	static def definition(String fileName) {
		fileName + DEFINITION_HEADER_EXT
	}
	
	static def declaration(String fileName) {
		fileName + DECLARATION_HEADER_EXT
	}
}
