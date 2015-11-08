/*
 * CheckExpression.h
 *
 *  Created on: Jun 3, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_OPERATIONS_CHECK_CHECKEXPRESSION_H_
#define LOCALSEARCH_OPERATIONS_CHECK_CHECKEXPRESSION_H_

#include "CheckOperation.h"

namespace Localsearch {
namespace Operations {
namespace Check {

/**
 * @brief Expression check for running simple expressions.
 *
 * This class handles running 'check(...expression...)' constraints on the model. This is done
 * via helper check classes containing the expression itself.
 *
 * @tparam Check The type of the helper check class.
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename Check, typename MatchingFrame>
class CheckExpression: public CheckOperation<MatchingFrame> {
public:
    /**
     * Creates an instance of an expression check using the specified check.
     *
     * @param check An instance of the class containing the proper check.
     */
    CheckExpression(Check check);

    bool check(MatchingFrame& frame, const Matcher::ISearchContext& context);

private:
    Check _check;
};

template<typename Check, typename MatchingFrame>
inline CheckExpression<Check, MatchingFrame>::CheckExpression(Check check) :
        _check(check) {
}

template<typename Check, typename MatchingFrame>
inline bool CheckExpression<Check, MatchingFrame>::check(MatchingFrame& frame, const Matcher::ISearchContext& context) {
    return _check(frame);
}

}  // namespace Check
}  // namespace Operations
}  // namespace Localsearch

#endif /* LOCALSEARCH_OPERATIONS_CHECK_CHECKEXPRESSION_H_ */
