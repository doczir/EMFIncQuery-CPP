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
package org.eclipse.viatra.query.localsearch.cpp.generator.internal.iterator

import org.eclipse.viatra.query.localsearch.cpp.generator.internal.common.QuerySpecificationGenerator
import org.eclipse.viatra.query.localsearch.cpp.generator.model.PatternBodyStub
import org.eclipse.viatra.query.localsearch.cpp.generator.model.PatternStub
import java.util.Set

/**
 * @author Robert Doczi
 */
class IteratorQuerySpecificationGenerator extends QuerySpecificationGenerator {
	
	new(String queryName, Set<PatternStub> patternGroup) {
		super(queryName, patternGroup)
	}
	
	override generatePlan(PatternStub pattern, PatternBodyStub patternBody) ''''''
	
		
}
