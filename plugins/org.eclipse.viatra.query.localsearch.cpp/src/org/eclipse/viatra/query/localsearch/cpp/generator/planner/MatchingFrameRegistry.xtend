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
package org.eclipse.viatra.query.localsearch.cpp.generator.planner

import java.util.Map
import org.eclipse.viatra.query.runtime.matchers.psystem.PBody
import org.eclipse.viatra.query.localsearch.cpp.generator.model.MatchingFrameStub
import com.google.common.base.Optional

/**
 * @author Robert Doczi
 */
class MatchingFrameRegistry {
	
	Map<PBody, MatchingFrameStub> frameMap = newHashMap;
	
	def getMatchingFrame(PBody pBody) {
		return Optional::fromNullable(frameMap.get(pBody))
	}
	
	def putMatchingFrame(PBody pBody, MatchingFrameStub frameStub) {
		frameMap.put(pBody, frameStub)
	}
		
}