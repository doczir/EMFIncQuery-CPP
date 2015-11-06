package hu.bme.mit.incquery.localsearch.cpp.ui.handler

import com.google.inject.Inject
import com.google.inject.Injector
import hu.bme.mit.incquery.localsearch.cpp.generator.internal.RuntimeGeneratorContext
import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException

class RuntimeGeneratorHandler extends AbstractHandler {
	
	@Inject Injector injector	
	
	override execute(ExecutionEvent event) throws ExecutionException {
		val generatorHandler = new GeneratorHandler
		injector.injectMembers(generatorHandler)
		generatorHandler.generate(event, RuntimeGeneratorContext)
		return null
	}

}
