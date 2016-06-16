#pragma once

namespace Viatra {
namespace Query {

template<class T>
struct ModelIndex {

	static std::list<T*>& instances() {
		static_assert(false, "Please specialize a model indexer for this type!");
	}
};

}  /* namespace Query*/
}  /* namespace Viatra*/