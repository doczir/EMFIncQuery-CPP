#pragma once

namespace Viatra {
namespace Query {

template<class T>
class QueryEngine {
public:
	static QueryEngine<T> of(const T *model);
	static QueryEngine<T> empty();

	template<template <typename> class S>
	typename S<T>::Matcher matcher();

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
template<template <typename> class S>
typename S<T>::Matcher QueryEngine<T>::matcher() {
	return typename S<T>::Matcher(_model, &S<T>::QueryGroup::instance().context());
}

template<class T>
QueryEngine<T>::QueryEngine(const T* model)
	: _model(model) {
	
}

} /* namespace Query */
} /* namespace Viatra */
