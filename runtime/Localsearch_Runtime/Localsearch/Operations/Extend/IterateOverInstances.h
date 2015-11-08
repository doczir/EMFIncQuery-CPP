/*
 * IterateOverInstances.h
 *
 *  Created on: Apr 21, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_OPERATIONS_EXTEND_ITERATEOVERINSTANCES_H_
#define LOCALSEARCH_OPERATIONS_EXTEND_ITERATEOVERINSTANCES_H_

#include "../../Util/Defs.h"
#include "ExtendOperation.h"

#include <list>
#include <type_traits>

namespace Localsearch {
namespace Operations {
namespace Extend {

/**
 * @brief Instance iteration.
 *
 * This extend operation binds a frame variable to an instance of a specified type.
 *
 * @tparam SrcType The type of the variable to be bound.
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename SrcType, typename MatchingFrame>
class IterateOverInstances: public ExtendOperation<SrcType, std::list<SrcType>, MatchingFrame> {
    typedef SrcType MatchingFrame::* BindPoint;
public:
    /**
     * Creates a new instance of an IterateOverInstances operation.
     *
     * @param bind The function used to bind the variable in a frame.
     * @param clazz The id of the type to be iterated.
     */
    IterateOverInstances(BindPoint bind, XTClass clazz);
    void on_initialize(MatchingFrame& frame, const Matcher::ISearchContext& context);
private:
    XTClass _clazz;

};

template<typename SrcType, typename MatchingFrame>
inline IterateOverInstances<SrcType, MatchingFrame>* create_IterateOverInstances(SrcType MatchingFrame::* bind, XTClass clazz) {
	return new IterateOverInstances<SrcType, MatchingFrame>(bind, clazz);
}

} /* namespace Extend */
} /* namespace Operations */
} /* namespace Localsearch */

template<typename SrcType, typename MatchingFrame>
inline Localsearch::Operations::Extend::IterateOverInstances<SrcType, MatchingFrame>::IterateOverInstances(
        BindPoint bind, XTClass clazz) :
        ExtendOperation<SrcType, std::list<SrcType>, MatchingFrame>(bind), _clazz(clazz) {
}

template<typename SrcType, typename MatchingFrame>
inline void Localsearch::Operations::Extend::IterateOverInstances<SrcType, MatchingFrame>::on_initialize(MatchingFrame&,
        const Matcher::ISearchContext&) {
    std::list<SrcType>& data = std::remove_pointer<SrcType>::type::_instances;
    ExtendOperation<SrcType, std::list<SrcType>, MatchingFrame>::set_data(data.begin(), data.end());
}

#endif /* LOCALSEARCH_OPERATIONS_EXTEND_ITERATEOVERINSTANCES_H_ */
