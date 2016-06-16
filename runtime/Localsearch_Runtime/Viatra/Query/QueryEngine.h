#pragma once

namespace Viatra {
namespace Query {

template<class T>
class QueryEngine {
public:
	static QueryEngine<T> of(const T *model);
	static QueryEngine<T> empty();

	template<class S>
	typename S::Matcher matcher() {
		return S::Matcher();
	}

private:
	QueryEngine(const T *model);
	
	const T *_model;
};

template<class T>
QueryEngine<T> QueryEngine<T>::of(const T *model) {
	return QueryEngine<T>(model);
}

template<class T>
QueryEngine<T> QueryEngine<T>::empty() {
	return QueryEngine<T>(nullptr);
}

template<class T>
QueryEngine<T>::QueryEngine(const T* model)
	: _model(model) {
	
}

} /* namespace Query */
} /* namespace Viatra */
