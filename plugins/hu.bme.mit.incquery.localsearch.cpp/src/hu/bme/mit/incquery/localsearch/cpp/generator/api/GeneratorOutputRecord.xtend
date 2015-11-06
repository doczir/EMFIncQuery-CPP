package hu.bme.mit.incquery.localsearch.cpp.generator.api

import org.eclipse.xtend.lib.annotations.Data

@Data
class GeneratorOutputRecord {
	
	val String folderPath
	val String fileName
	val CharSequence content
}