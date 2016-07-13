/*******************************************************************************
 * Copyright (c) 2014-2016 Robert Doczi, IncQuery Labs Ltd.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Robert Doczi - initial API and implementation
 *******************************************************************************/
package org.eclipse.viatra.query.localsearch.cpp.generator

import org.eclipse.viatra.query.localsearch.cpp.generator.api.IGeneratorOutputProvider
import org.eclipse.viatra.query.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import org.eclipse.viatra.query.localsearch.cpp.generator.model.QueryStub
import org.eclipse.viatra.query.localsearch.cpp.generator.planner.PlanCompiler
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.viatra.query.patternlanguage.emf.eMFPatternLanguage.PatternModel
import org.eclipse.emf.ecore.EClass

/**
 * @author Robert Doczi
 */
class LocalSearchCppGenerator {

	ILocalsearchGeneratorOutputProvider generator

	new(Class<? extends ILocalsearchGeneratorOutputProvider> generator) {
		this.generator = generator.newInstance
	}

	def IGeneratorOutputProvider generate(String queryFileName, Resource resource, List<PQuery> queries) {

		val patternModel = resource.contents.get(0) as PatternModel
		val classes = patternModel.importPackages.packageImport.map[it.EPackage].map[it.EClassifiers].flatten.filter(EClass).toSet

		val planCompiler = new PlanCompiler
		val patternStubs = queries.map[
			planCompiler.compilePlan(it)
		].flatten.toSet

		val queryStub = new QueryStub(queryFileName, patternStubs, classes)
		generator.initialize(queryStub)

		return generator
	}

}