package hu.bme.mit.incquery.localsearch.cpp.ui;

import org.eclipse.incquery.patternlanguage.emf.ui.internal.EMFPatternLanguageActivator;
import org.eclipse.xtext.ui.guice.AbstractGuiceAwareExecutableExtensionFactory;
import org.osgi.framework.Bundle;

import com.google.inject.Injector;

public class GeneratorExecutableExtensionFactory extends AbstractGuiceAwareExecutableExtensionFactory {

	@Override
	protected Bundle getBundle() {
		return Activator.getDefault().getBundle();
	}

	@Override
	protected Injector getInjector() {
		return EMFPatternLanguageActivator.getInstance().getInjector(EMFPatternLanguageActivator.ORG_ECLIPSE_INCQUERY_PATTERNLANGUAGE_EMF_EMFPATTERNLANGUAGE);
	}

}
