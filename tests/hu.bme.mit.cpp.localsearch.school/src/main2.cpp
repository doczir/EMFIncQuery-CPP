#include "Viatra\Query\Matcher\ModelIndex.h"

#include <unordered_set>
#include <functional>
#include <iostream>

#include "school_def.h"
#include "Viatra\Query\School\SchoolsMatcher.h"
#include "Viatra\Query\School\TeachersOfSchoolMatcher.h"
#include "Viatra\Query\School\TeacherNameMatcher.h"
#include "Viatra\Query\School\TeachersWithActualWorkMatcher.h"
#include "Viatra\Query\School\TeachersWithoutWorkMatcher.h"

using namespace ::school;

namespace Viatra {
	namespace Query {
		template<>
		struct ModelIndex<::school::School, ::school::School> {
			static const std::list<::school::School*>& instances(const ::school::School* modelroot) {
				return ::school::School::_instances;
			}
		};

		template<>
		struct ModelIndex<::school::Teacher, ::school::School> {
			static const std::list<::school::Teacher*>& instances(const ::school::School* modelroot) {
				return ::school::Teacher::_instances;
			}
		};
	}
}


int main() {
	auto s = new School();
	s->name = "A";
	auto t = new Teacher();
	t->name = "Sándor";
	s->teachers.push_back(t);
	t = new Teacher();
	t->name = "Boldizsár";
	s->teachers.push_back(t);
	t = new Teacher();
	t->name = "Benedek";
	s->teachers.push_back(t);
	s = new School();
	s->name = "B";
	t = new Teacher();
	t->name = "Botond";
	s->teachers.push_back(t);
	s = new School();
	s->name = "C";
	t = new Teacher();
	t->name = "Ádám";
	s->teachers.push_back(t);
	t = new Teacher();
	t->name = "Dezso";
	auto co = new Course();
	t->courses.push_back(co);
	s->teachers.push_back(t);
	s = new School();
	s->name = "D";
	t = new Teacher();
	t->name = "Béla";
	s->teachers.push_back(t);
	auto c = new SchoolClass();
	t->homeroomedClass = c;


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
		auto matcher = engine.matcher<::Viatra::Query::School::TeachersOfSchoolQuerySpecification>();
		auto matches = matcher.matches(s);

		int i = 0;
		for (auto&& sch : matches) {
			std::cout << "School{" << sch.school->name << "}" << " Teacher{" << sch.teacher->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		auto matcher = engine.matcher<::Viatra::Query::School::TeacherNameQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& sch : matches) {
			std::cout << "name {" << sch.name << "}" << " Teacher{" << sch.teacher->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		std::cout << "Teachers with work: " << std::endl;
		auto matcher = engine.matcher<::Viatra::Query::School::TeachersWithActualWorkQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& sch : matches) {
			std::cout << " Teacher{" << sch.teacher->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	{
		std::cout << "Teachers without work: " << std::endl;
		auto matcher = engine.matcher<::Viatra::Query::School::TeachersWithoutWorkQuerySpecification>();
		auto matches = matcher.matches();

		int i = 0;
		for (auto&& sch : matches) {
			std::cout << " Teacher{" << sch.teacher->name << "}" << std::endl;
			if (i++ > 10) {
				break;
			}
		}
	}

	return 0;
}