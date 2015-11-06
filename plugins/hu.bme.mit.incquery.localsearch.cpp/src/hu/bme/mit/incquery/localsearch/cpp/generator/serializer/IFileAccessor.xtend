package hu.bme.mit.incquery.localsearch.cpp.generator.serializer

interface IFileAccessor {

	def void createFile(String folderPath, String fileName, CharSequence contents)

	def void deleteFile(String folderPath, String fileName)

	def void createFolder(String folderPath, String folderName)

}