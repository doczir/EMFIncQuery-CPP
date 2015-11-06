package hu.bme.mit.incquery.localsearch.cpp.ui.handler;

import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.incquery.patternlanguage.emf.eMFPatternLanguage.PatternModel;
import org.eclipse.incquery.patternlanguage.emf.specification.SpecificationBuilder;
import org.eclipse.incquery.runtime.matchers.psystem.queries.PQuery;

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
