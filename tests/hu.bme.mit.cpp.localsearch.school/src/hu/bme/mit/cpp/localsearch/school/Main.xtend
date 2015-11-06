package hu.bme.mit.cpp.localsearch.school

import com.google.common.base.Stopwatch
import hu.bme.mit.cpp.localsearch.school.query.util.StudentsOfSchoolQuerySpecification
import java.util.Collection
import java.util.List
import java.util.Random
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.eclipse.incquery.runtime.api.AdvancedIncQueryEngine
import org.eclipse.incquery.runtime.api.IPatternMatch
import org.eclipse.incquery.runtime.api.IQuerySpecification
import org.eclipse.incquery.runtime.api.IncQueryMatcher
import org.eclipse.incquery.runtime.emf.EMFScope
import org.eclipse.incquery.runtime.extensibility.QueryBackendRegistry
import org.eclipse.incquery.runtime.localsearch.matcher.integration.LocalSearchBackend
import org.eclipse.incquery.runtime.localsearch.matcher.integration.LocalSearchBackendFactory
import org.eclipse.incquery.runtime.matchers.backend.QueryEvaluationHint
import school.SchoolFactory
import java.util.concurrent.TimeUnit

class Main {

	static val SEED = 0;
	static val random = new Random(SEED)

	static val YEARS = 5
	static val COURSES = 20
	static val CLASSES = 4
	static val STUDENTS = 500
	static val TEACHERS = 10

	static val COURSES_PER_CLASS = 5
	static val COURSES_PER_TEACHER = 2

	long currentId = 0;
	ResourceSet schoolSet = new ResourceSetImpl;

	def getAlphabeticString(int length) {
		val chars = "abcdefghijklmnopqrstvwxyz"
		getRandomString(random, chars, length)
	}

	def getAlphaNumericString(int length) {
		val chars = "ABCDEFGHIJKLMNOPQRSTVWXYZ1234567890"
		getRandomString(random, chars, length)
	}

	def getRandomString(Random rnd, String characters, int length) {
		val StringBuilder sb = new StringBuilder;
		for (i : 0 ..< length) {
			sb.append(characters.charAt(rnd.nextInt(characters.length)))
		}
		return sb.toString
	}

	def getUniqueId() {
		val id = currentId;
		currentId++;
		return id;
	}
	
	def init() {
		// load the school ecore model
		schoolSet.createResource(URI::createPlatformResourceURI("BUTE.school", true))
	}

	def initModel(int size) {
		println('''Initializing model (scale : «size»)''')
		extension val factory = SchoolFactory.eINSTANCE
		
		schoolSet.resources.clear
		
		for (i : 0 ..< size) {
			val schoolResource = schoolSet.createResource(URI::createPlatformResourceURI("BUTE.school", true))
			val school = createSchool => [
				name = "Budapest Institute of Technology and Economics" + i
			]
			schoolResource.contents.add(school)

			for (j : 0 ..< YEARS) {
				school.years.add(createYear => [
					it.school = school
					it.startingDate = 2010 + j
				])
			}

			for (j : 0 ..< COURSES) {
				school.courses.add(createCourse => [
					subject = getAlphabeticString(16)
					weight = random.nextInt(100)
				])
			}

			for (j : 0 ..< CLASSES) {
				school.years.get(j % YEARS).schoolClasses.add(createSchoolClass => [
					code = getAlphabeticString(1).charAt(0)
					for (k : 0 ..< COURSES_PER_CLASS) {
						courses.add(school.courses.get(j * COURSES_PER_CLASS + k % COURSES))
					}
				])
			}

			val students = newArrayList
			for (j : 0 ..< STUDENTS) {
				val student = createStudent => [
					name = '''«getAlphabeticString(6).toFirstUpper» «getAlphabeticString(6).toFirstUpper»'''
					for (k : 0 ..< Math.floor(Math.sqrt(j)) as int) {
						friendsWith.add(students.get(k))
					}
				]
				school.years.map[schoolClasses].flatten.get(j % CLASSES).students.add(student)
				students.add(student)
			}

			for (j : 0 ..< TEACHERS) {
				school.teachers.add(createTeacher => [
					name = '''«getAlphabeticString(6).toFirstUpper» «getAlphabeticString(6).toFirstUpper»'''
					for (k : 0 ..< COURSES_PER_TEACHER) {
						val course = school.courses.get(j % COURSES)
						courses.add(course)
						if (k == 0) {
							homeroomedClass = course.schoolClass
						}
					}
				])
			}
		}
	}

	def void query(int runs, List<IQuerySpecification<? extends IncQueryMatcher<? extends IPatternMatch>>> patterns) {
		
		for(patternSpecification : patterns) {
			println('''Preparing query: «patternSpecification.fullyQualifiedName»''')		
			
			val hint = new QueryEvaluationHint(LocalSearchBackend, newHashMap)
			
			val sw = Stopwatch::createUnstarted
			var Collection<? extends IPatternMatch> matches 
			for(i : 1..runs) {
				val engine = AdvancedIncQueryEngine::createUnmanagedEngine(new EMFScope(schoolSet))
				
				sw.start				
				val matcher = AdvancedIncQueryEngine.from(engine).getMatcher(patternSpecification, hint)
				matches = matcher.allMatches
				sw.stop
				engine.dispose
//				if(i % (runs/10) == 0)
//					println('''querying {«(i as float) / runs * 100.0f»%}''')
			}
			
			println('''Elapsed time: «sw.elapsed(TimeUnit::MICROSECONDS) / runs» us''')
			println(matches.size)	
		}
		
	}
	
	def void run(int levels, int runs, List<IQuerySpecification<? extends IncQueryMatcher<? extends IPatternMatch>>> patterns) {
		for(i : 0..<levels) {
			initModel(Math.pow(2, i) as int)
			query(runs, #[StudentsOfSchoolQuerySpecification::instance])
		}
	}

	def static void main(String[] args) {
		QueryBackendRegistry.getInstance().registerQueryBackendFactory(LocalSearchBackend,
			new LocalSearchBackendFactory());
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("ecore", new EcoreResourceFactoryImpl);
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("school", new XMIResourceFactoryImpl);
		
		val main = new Main
		main.init
		main.run(6, 100, #[])
		
	}

}