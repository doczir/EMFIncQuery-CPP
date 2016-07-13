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
package org.eclipse.viatra.query.localsearch.cpp.ui.handler;

import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.viatra.query.patternlanguage.emf.eMFPatternLanguage.PatternModel;
import org.eclipse.viatra.query.patternlanguage.emf.specification.SpecificationBuilder;
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery;

/**
 * @author Robert Doczi
 */
public class ASTtoPQueriesHelper {

	public static List<PQuery> astToPQueries(PatternModel ast) {
		SpecificationBuilder specBuilder = new SpecificationBuilder();
		return ast.getPatterns().stream().map(pattern -> {
			try {
				return specBuilder.getOrCreateSpecification(pattern).getInternalQueryRepresentation();
			} catch (Exception e) {
				e.printStackTrace();
				return null;
			}
		}).filter(v -> v != null).collect(Collectors.toList());
	}
	
}
