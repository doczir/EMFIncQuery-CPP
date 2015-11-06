package hu.bme.mit.incquery.localsearch.cpp.generator.serializer

import hu.bme.mit.incquery.localsearch.cpp.generator.api.IGeneratorOutputProvider

interface ISerializer {
	def void serialize(String folderPath, IGeneratorOutputProvider provider, IFileAccessor fileAccessor)
	
	def void createFolder(String folderPath, String folderName, IFileAccessor fileAccessor)		
}