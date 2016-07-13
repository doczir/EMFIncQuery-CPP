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
package org.eclipse.viatra.query.localsearch.cpp.generator.internal

import org.eclipse.viatra.query.localsearch.cpp.generator.api.GeneratorOutputRecord
import org.eclipse.viatra.query.localsearch.cpp.generator.api.ILocalsearchGeneratorOutputProvider
import org.eclipse.viatra.query.localsearch.cpp.generator.model.QueryStub
import java.util.Collection

/**
 * @author Robert Doczi
 */
abstract class LocalsearchGeneratorOutputProvider implements ILocalsearchGeneratorOutputProvider {
	
	var QueryStub query

	override initialize(QueryStub query) {
		this.query = query
	}

	override getOutput() {
		val generators = initializeGenerators(query)
		val root = "Viatra/Query"

		return generators.map[
			new GeneratorOutputRecord('''«root»/«query.name.toFirstUpper»''', fileName, compile)
		].toList
	}

	def Collection<IGenerator> initializeGenerators(QueryStub query)
	
}