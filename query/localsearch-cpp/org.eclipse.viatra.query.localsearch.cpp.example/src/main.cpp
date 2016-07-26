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


#include "cyberPhysicalSystem_def.h"

#include "Viatra\Query\QueryEngine.h"
#include "Viatra\Query\Matcher\ModelIndex.h"
#include "Viatra\Query\CPS\CommunicatingTypesMatcher.h"

#include <cmath>
#include <chrono>
#include <iostream>
#include <functional>
#include <string>
#include <vector>

using namespace ::cyberPhysicalSystem;

namespace Viatra {
	namespace Query {
		template<>
		struct ModelIndex<::cyberPhysicalSystem::ApplicationType, ::cyberPhysicalSystem::CyberPhysicalSystem> {
			static const std::list<::cyberPhysicalSystem::ApplicationType*>& instances(const ::cyberPhysicalSystem::CyberPhysicalSystem* modelroot) {
				return ::cyberPhysicalSystem::ApplicationType::_instances;
			}
		};

		template<>
		struct ModelIndex<::cyberPhysicalSystem::HostType, ::cyberPhysicalSystem::CyberPhysicalSystem> {
			static const std::list<::cyberPhysicalSystem::HostType*>& instances(const ::cyberPhysicalSystem::CyberPhysicalSystem* modelroot) {
				return ::cyberPhysicalSystem::HostType::_instances;
			}
		};

	}
}

std::vector<CyberPhysicalSystem*> cpss;

const int HOST_TYPES = 5;
const int HOST_INSTANCES = 20;
const int APP_TYPES = 10;
const int APP_INSTANCES = 500;

const int REQUIREMENTS_PER_APP_TYPE = 10;
const int APP_INSTANCES_PER_HOST_INSTANCES = 5;

std::string get_random_string(const std::string& characters, int length) {
	std::string ret;
	for (int i = 0; i < length; ++i) {
		ret += characters[rand() % characters.size()];
	}

	return ret;
}

std::string get_alpha_string(int length) {
	return get_random_string("abcdefghijklmnopqrstvwxyz", length);
}

std::string get_alphanumeric_string(int length) {
	return get_random_string("ABCDEFGHIJKLMNOPQRSTVWXYZ1234567890", length);
}

template <typename I>
I random_element(I begin, I end)
{
	const unsigned long n = std::distance(begin, end);
	const unsigned long divisor = (RAND_MAX + 1) / n;

	unsigned long k;
	do { k = std::rand() / divisor; } while (k >= n);

	std::advance(begin, k);
	return begin;
}

long get_unique_id() {
	static long id = 0;
	long new_id = id++;
	return new_id;
}

void init_model(int scale) {
	std::cout << "Initializing model (scale : " << scale << ")" << std::endl;

	for (int i = 0; i < scale; ++i) {
		auto cps = new CyberPhysicalSystem();
		cpss.push_back(cps);

		for (int j = 0; j < APP_TYPES; ++j) {
			auto appType = new ApplicationType();
			appType->cps = cps;
			cps->identifier = get_alpha_string(12);

			cps->appTypes.push_back(appType);

			for (int j = 0; j < APP_INSTANCES; ++j) {
				auto appInstance = new ApplicationInstance();
				appInstance->identifier = get_alpha_string(12);
				appInstance->type = appType;

				appType->instances.push_back(appInstance);
			}

			for (int j = 0; j < REQUIREMENTS_PER_APP_TYPE; ++j) {
				auto requirement = new ResourceRequirement();
				requirement->identifier = get_alphanumeric_string(6);

				appType->requirements.push_back(requirement);
			}
		}

		for (int j = 0; j < HOST_TYPES; ++j) {
			auto hostType = new HostType();
			hostType->identifier = get_alpha_string(12);

			cps->hostTypes.push_back(hostType);

			for (int j = 0; j < HOST_INSTANCES; ++j) {
				auto hostInstance = new HostInstance();
				hostInstance->identifier = get_alpha_string(12);

				hostType->instances.push_back(hostInstance);
			}
		}

	}
}

void query(int runs) {
	int size;

	auto start = std::chrono::high_resolution_clock::now();

	auto engine = ::Viatra::Query::QueryEngine<CyberPhysicalSystem>::empty();
	auto matcher = engine.matcher<::Viatra::Query::Cps::CommunicatingTypesQuerySpecification>();

	for (int i = 0; i < runs; ++i) {

		auto sos = matcher.matches();
		size = sos.size();
	}

	auto end = std::chrono::high_resolution_clock::now();
	auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();

	std::cout << size << std::endl;
	std::cout << "Elapsed time: " << elapsed / runs << " us" << std::endl;
}

void cleanup_model() {
	for (auto&& cps : cpss) {
		for (auto&& appType : cps->appTypes) {
			for (auto&& appInstance : appType->instances) {
				delete appInstance;
			}
			for (auto&& requirement : appType->requirements) {
				delete requirement;
			}
			delete appType;
		}

		for (auto&& hostType : cps->hostTypes) {
			for (auto&& hostInstance : hostType->instances) {
				delete hostInstance;
			}
			delete hostType;
		}
	}

	cpss.clear();
}

void run(int levels, int runs) {
	for (int i = 0; i < levels; ++i) {
		init_model(pow(2, i));
		query(runs);
		cleanup_model();
	}
}

int main(int argc, char **argv) {
	std::cout << "start" << std::endl;
	run(6, 1);
}
