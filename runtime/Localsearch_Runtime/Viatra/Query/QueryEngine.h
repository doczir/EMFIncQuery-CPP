#pragma once

namespace Viatra {
namespace Query {

template<class ModelRoot>
class QueryEngine {
public:
	static QueryEngine<ModelRoot> of(const ModelRoot *model);
	static QueryEngine<ModelRoot> empty();

	template<template <typename> class QuerySpecification>
	typename QuerySpecification<ModelRoot>::Matcher matcher();

private:
	QueryEngine(const ModelRoot *model);
	
	const ModelRoot *_model;
};

template<class ModelRoot>
QueryEngine<ModelRoot> QueryEngine<ModelRoot>::of(const ModelRoot *model) {
	return QueryEngine<ModelRoot>(model);
}

template<class ModelRoot>
QueryEngine<ModelRoot> QueryEngine<ModelRoot>::empty() {
	return QueryEngine<ModelRoot>(nullptr);
}

template<class ModelRoot>
template<template <class> class QuerySpecification>
typename QuerySpecification<ModelRoot>::Matcher QueryEngine<ModelRoot>::matcher() {
	return typename QuerySpecification<ModelRoot>::Matcher(_model, &QuerySpecification<ModelRoot>::QueryGroup::instance().context());
}

template<class ModelRoot>
QueryEngine<ModelRoot>::QueryEngine(const ModelRoot* model)
	: _model(model) {
	
}

} /* namespace Query */
} /* namespace Viatra */
