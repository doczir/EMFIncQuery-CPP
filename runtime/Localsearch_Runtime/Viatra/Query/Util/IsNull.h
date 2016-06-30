#pragma once

namespace Viatra {
namespace Query {
namespace Util {

/**
* @brief Nullptr checker utility.
*
* This helper struct allows the checking for a nullptr regardless if the type is a pointer. Returns false for
* non pointer values (as they can never be nullptr).
*
* @tparam T Type of the parameter.
*/
template<class T>
struct IsNull {
	static bool check(const T) {
		return false;
	}
};

template<class T>
struct IsNull<T*> {
	static bool check(const T* val) {
		return val == nullptr;
	}
};

}  /* namespace Util*/
}  /* namespace Query*/
}  /* namespace Viatra */
