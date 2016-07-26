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
#include "Viatra\Query\Matcher\ModelIndex.h"

#include <unordered_set>
#include <functional>
#include <iostream>

#include "cyberPhysicalSystem_def.h"
#include "Viatra\Query\CPS\HostInstancesMatcher.h"
#include "Viatra\Query\CPS\ApplicationNameMatcher.h"
#include "Viatra\Query\CPS\UsefulApplicationMatcher.h"
#include "Viatra\Query\CPS\UselessApplicationMatcher.h"

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
struct ModelIndex<::cyberPhysicalSystem::AppInstance, ::cyberPhysicalSystem::CyberPhysicalSystem> {
	static const std::list<::cyberPhysicalSystem::AppInstance*>& instances(const ::cyberPhysicalSystem::CyberPhysicalSystem* modelroot) {
		return ::cyberPhysicalSystem::AppInstance::_instances;
	}
};

template<>
struct ModelIndex<::cyberPhysicalSystem::HostType, ::cyberPhysicalSystem::CyberPhysicalSystem> {
	static const std::list<::cyberPhysicalSystem::HostType*>& instances(const ::cyberPhysicalSystem::CyberPhysicalSystem* modelroot) {
		return ::cyberPhysicalSystem::HostType::_instances;
	}
};

template<>
struct ModelIndex<::cyberPhysicalSystem::HostInstance, ::cyberPhysicalSystem::CyberPhysicalSystem> {
	static const std::list<::cyberPhysicalSystem::HostInstance*>& instances(const ::cyberPhysicalSystem::CyberPhysicalSystem* modelroot) {
		return ::cyberPhysicalSystem::HostInstance::_instances;
	}
};

}
}


int main() {
	auto at = new ApplicationType();
	at->identifier = "at1";
	auto ai = new ApplicationInstance();
	ai->identifier = "ai1";
	ai->type = at;
	at->instances.push_back(ai);
	ai = new ApplicationInstance();
	ai->identifier = "ai2";
	ai->type = at;
	at->instances.push_back(ai);
	at = new ApplicationType();
	at->identifier = "at2";
	at = new ApplicationType();
	at->identifier = "at3";
	ai = new ApplicationInstance();
	ai->identifier = "ai3";
	ai->type = at;
	at->instances.push_back(ai);
	auto ht = new HostType();
	ht->identifier = "ht1";
	auto hi = new HostInstance();
	hi->identifier = "hi1";
	ht->instances.push_back(hi);
	ai->allocatedTo = hi;
	hi->applications.push_back(ai);

	auto engine = ::Viatra::Query::QueryEngine<School>::of((School*)0x12345678); 

	//{
	//	auto matcher = engine.matcher<::Viatra::Query::School::SchoolsQuerySpecification>();
	//	auto matches = matcher.matches();

	//	int i = 0;
	//	for (auto&& sch : matches) {
	//		std::cout << "School{" << sch.school->name << "}" << std::endl;
	//		if (i++ > 10) {
	//			break;
	//		}
	//	}
	//}

	{
		auto matcher = engine.matcher<::Viatra::Query::CPS::HostInstancesQuerySpecification>();
		auto matches = matcher.matches(s);

		int i = 0;
		for (auto&& m : matches) {
			std::cout << "HostInstance{" << m.hostInstance->identifier<< "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		auto matcher = engine.matcher<::Viatra::Query::CPS::ApplicationNameQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& m : matches) {
			std::cout << "name {" << m.name << "}" << " ApplicationInstance{" << m.appInstance->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		std::cout << "Teachers with work: " << std::endl;
		auto matcher = engine.matcher<::Viatra::Query::CPS::UsefulApplicationTypesQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& m : matches) {
			std::cout << " ApplicationType{" << m.appType->identifier<< "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		std::cout << "Teachers without work: " << std::endl;
		auto matcher = engine.matcher<::Viatra::Query::CPS::UselessApplicationTypesQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& m : matches) {
			std::cout << " ApplicationType{" << m.teacher->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	return 0;
}
