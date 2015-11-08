/*
 * SearchPlan.h
 *
 *  Created on: Apr 19, 2015
 *      Author: doczir
 */

#ifndef LOCALSEARCH_PLAN_SEARCHPLAN_H_
#define LOCALSEARCH_PLAN_SEARCHPLAN_H_

#include <vector>

#include "../Operations/ISearchOperation.h"

namespace Localsearch {
namespace Plan {

/**
 * @brief A search plan.
 *
 * This class represents a search plan consisting of Operations::ISearchOperation.
 *
 * @tparam MatchingFrame The frame the operations will be executed on.
 */
template<typename MatchingFrame>
class SearchPlan {
public:
    ~SearchPlan();

    /**
     * Adds a new operation to the search plan. This takes ownership of the operation.
     *
     * @param operation The search operation to add.
     */
    void add_operation(Operations::ISearchOperation<MatchingFrame>* operation);

    /**
     * Adds a collection of new operations to the search plan. This takes ownership of the operations.
     *
     * @param operation The vector of operations to add.
     */
    void add_operation(std::vector<Operations::ISearchOperation<MatchingFrame>*> operations);

    /**
     * Returns the vector of operations contained in the plan.
     *
     * @return The std::vector of instances of Operations::ISearchOperation.
     */
    const std::vector<Operations::ISearchOperation<MatchingFrame>*>& get_operations() const;
private:
    std::vector<Operations::ISearchOperation<MatchingFrame>*> _operations;
};

} /* namespace Plan */
} /* namespace Localsearch */

template<typename MatchingFrame>
inline Localsearch::Plan::SearchPlan<MatchingFrame>::~SearchPlan() {
    for (typename std::vector<Localsearch::Operations::ISearchOperation<MatchingFrame>*>::iterator it =
            _operations.begin(); it != _operations.end(); it++) {
        delete *it;
    }
}

template<typename MatchingFrame>
inline void Localsearch::Plan::SearchPlan<MatchingFrame>::add_operation(
        Operations::ISearchOperation<MatchingFrame>* operation) {
    _operations.push_back(operation);
}

template<typename MatchingFrame>
inline void Localsearch::Plan::SearchPlan<MatchingFrame>::add_operation(
        std::vector<Operations::ISearchOperation<MatchingFrame> *> operations) {
    _operations.insert(_operations.end(), operations.begin(), operations.end());
}

template<typename MatchingFrame>
inline const std::vector<Localsearch::Operations::ISearchOperation<MatchingFrame> *>& Localsearch::Plan::SearchPlan<
        MatchingFrame>::get_operations() const {
    return _operations;
}

#endif /* LOCALSEARCH_PLAN_SEARCHPLAN_H_ */
