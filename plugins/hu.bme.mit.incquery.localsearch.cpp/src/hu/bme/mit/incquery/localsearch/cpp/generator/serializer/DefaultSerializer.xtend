package hu.bme.mit.incquery.localsearch.cpp.generator.serializer

import hu.bme.mit.incquery.localsearch.cpp.generator.api.IGeneratorOutputProvider
import java.io.File

class DefaultSerializer implements ISerializer {
	
	override serialize(String folderPath, IGeneratorOutputProvider provider, IFileAccessor fileAccessor) {
		provider.output.forEach[
			fileAccessor.createFile('''«folderPath»«File.separator»«it.folderPath»''', fileName, content)
		]
	}
	
	override createFolder(String folderPath, String folderName, IFileAccessor fileAccessor) {
		fileAccessor.createFolder(folderPath, folderName)
	}
	
}