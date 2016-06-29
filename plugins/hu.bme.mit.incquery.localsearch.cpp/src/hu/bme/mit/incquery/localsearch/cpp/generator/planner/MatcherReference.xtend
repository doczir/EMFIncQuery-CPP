package hu.bme.mit.incquery.localsearch.cpp.generator.planner

import java.util.Set
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PParameter
import org.eclipse.viatra.query.runtime.matchers.psystem.queries.PQuery
import org.eclipse.xtend.lib.annotations.Data

@Data
class MatcherReference {
	PQuery referredQuery
	Set<PParameter> adornment
}