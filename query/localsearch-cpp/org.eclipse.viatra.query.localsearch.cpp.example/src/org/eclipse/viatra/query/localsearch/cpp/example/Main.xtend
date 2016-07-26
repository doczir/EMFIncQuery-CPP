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
package org.eclipse.viatra.query.localsearch.cpp.example

import com.google.common.base.Stopwatch
import com.google.common.collect.Lists
import com.google.common.collect.Sets
import java.util.List
import java.util.Random
import java.util.concurrent.TimeUnit
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.eclipse.viatra.examples.cps.cyberPhysicalSystem.CyberPhysicalSystemFactory
import org.eclipse.viatra.query.localsearch.cpp.example.query.util.CommunicatingTypesQuerySpecification
import org.eclipse.viatra.query.runtime.api.AdvancedViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.IQuerySpecification
import org.eclipse.viatra.query.runtime.api.ViatraQueryMatcher
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.query.runtime.localsearch.matcher.integration.LocalSearchBackendFactory
import org.eclipse.viatra.query.runtime.localsearch.matcher.integration.LocalSearchHintKeys
import org.eclipse.viatra.query.runtime.matchers.backend.QueryEvaluationHint

/**
 * @author Robert Doczi
 */
class Main {

	static val SEED = 0;
	static val random = new Random(SEED)

	static val HOST_TYPES = 5
	static val HOST_INSTANCES = 20
	static val APP_TYPES = 10
	static val APP_INSTANCES = 500

	static val REQUIREMENTS_PER_APP_TYPE = 10
	static val APP_INSTANCES_PER_HOST_INSTANCES = 5

	long currentId = 0;
	ResourceSet cpsResourceSet = new ResourceSetImpl;

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

	def <E> getRandom(Iterable<E> iterable) {
		val n = iterable.size
		if (n == 0)
			return null

		val rnd = random.nextDouble
		val idx = Math.round(rnd * n - 1) as int;

		return iterable.get(idx)
	}

	def <E> getRandom(Iterable<E> iterable, int count) {
		if (count <= 0)
			return #{}

		val n = iterable.size
		if (n == 0)
			return #{}

		if (count > n)
			return Sets::newHashSet(iterable)

		val data = Lists::newLinkedList(iterable)
		val resultData = newHashSet
		
		for(i : 0 ..< count) {
			val rnd = random.nextDouble
			val idx = Math.max(0, Math.round((rnd * data.size) - 1)) as int;
			
			resultData += data.get(idx)
			data.remove(idx)
		}

		return resultData
	}

	def getUniqueId() {
		val id = currentId;
		currentId++;
		return id;
	}

	def init() {
		cpsResourceSet.createResource(URI::createPlatformResourceURI("example.cyberphysicalsystem", true))
	}

	def initModel(int size) {
		println('''Initializing model (scale : «size»)''')
		extension val factory = CyberPhysicalSystemFactory.eINSTANCE

		cpsResourceSet.resources.clear

		val cpsResource = cpsResourceSet.createResource(URI::createPlatformResourceURI("example.cyberphysicalsystem", true))
		for (i : 0 ..< size) {
			val cps = createCyberPhysicalSystem

			cpsResource.contents.add(cps)

			for (j : 0 ..< APP_TYPES) {
				val appType = createApplicationType => [
					it.identifier = getAlphabeticString(12)
				]
				cps.appTypes += appType

				for (k : 0 ..< APP_INSTANCES) {
					appType.instances += createApplicationInstance => [
						it.identifier = getAlphabeticString(12)

					]
				}
				
				for (k : 0 ..< REQUIREMENTS_PER_APP_TYPE) {
					appType.requirements += createResourceRequirement => [
						it.identifier = getAlphaNumericString(6)
					]
				} 
			}

			for (j : 0 ..< HOST_TYPES) {
				val hostType = createHostType => [
					it.identifier = getAlphabeticString(12)
				]
				cps.hostTypes += hostType

				for (k : 0 ..< HOST_INSTANCES) {
					hostType.instances += createHostInstance => [
						it.identifier = getAlphabeticString(12)
						it.applications += cps.appTypes.map[instances].flatten.getRandom(APP_INSTANCES_PER_HOST_INSTANCES)
					]
				}
			}
		}

	}

	def void query(int runs,
		List<IQuerySpecification<? extends ViatraQueryMatcher<? extends IPatternMatch>>> patterns) {

		for (patternSpecification : patterns) {
			println('''Preparing query: «patternSpecification.fullyQualifiedName»''')

			val hint = new QueryEvaluationHint(LocalSearchBackendFactory.INSTANCE, #{
				LocalSearchHintKeys::USE_BASE_INDEX -> false
			})

			val sw = Stopwatch::createUnstarted
			var deltaMem = 0.0;
			for (i : 1 .. runs) {
				for (j : 0 ..< 10)
					System.gc
				val memStart = Runtime.runtime.totalMemory - Runtime.runtime.freeMemory
				sw.start
				val engine = AdvancedViatraQueryEngine::createUnmanagedEngine(new EMFScope(cpsResourceSet))

				val matcher = engine.getMatcher(patternSpecification ,hint)
				val count = matcher.countMatches
				
				println(count)

				sw.stop
				val memEnd = Runtime.runtime.totalMemory - Runtime.runtime.freeMemory
				deltaMem = memEnd - memStart;
				engine.dispose
			}

			println('''Elapsed time: «sw.elapsed(TimeUnit::MICROSECONDS) / runs» us''')
			println('''Memory usage: «(deltaMem / runs) / 1024» kb''')
			// println(matches.size)
			for (i : 0 ..< 10)
				System.gc
		}

	}

	def void run(int levels, int runs,
		List<IQuerySpecification<? extends ViatraQueryMatcher<? extends IPatternMatch>>> patterns) {
		for (i : 0 ..< levels) {
			initModel(Math.pow(2, i) as int)
			query(runs, #[CommunicatingTypesQuerySpecification::instance])
		}
	}

	def static void main(String[] args) {
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("ecore", new EcoreResourceFactoryImpl);
		Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().put("cyberphysicalsystem", new XMIResourceFactoryImpl);

		val main = new Main
		main.init
		main.run(6, 10, #[])
	}
}
