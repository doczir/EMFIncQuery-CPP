#pragma once

namespace Viatra {
namespace Query {

template<class Class, class ModelRoot>
struct ModelIndex {

	static const std::list<Class*>& instances(const ModelRoot* modelroot) {
		static_assert(false, "Please specialize a model indexer for this type!");
	}
};

}  /* namespace Query*/
}  /* namespace Viatra*/