/*
 * CheckOperation.h
 *
 *  Created on: Apr 16, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_OPERATIONS_CHECK_CHECKOPERATION_H_
#define LOCALSEARCH_OPERATIONS_CHECK_CHECKOPERATION_H_

#include "../ISearchOperation.h"

namespace Localsearch {
namespace Operations {
namespace Check {

/**
 * @brief A check operation.
 *
 * This operation represents a check operation, meaning it will not bind any values in the
 * frame, it only checks if the already bound values satisfy a specific type of constraint.
 *
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename MatchingFrame>
class CheckOperation: public ISearchOperation<MatchingFrame> {
public:

    /**
     * Creates a new CheckOperation.
     */
    CheckOperation() :
            _executed(false) {
    }

    /**
     * Destroys a CheckOperation instance.
     */
    virtual ~CheckOperation() {
    }

    void on_initialize(MatchingFrame&, const Matcher::ISearchContext&) {
        _executed = false;
    }

    void on_backtrack(MatchingFrame&, const Matcher::ISearchContext&) {
        // nop
    }

    /**
     * Executes the check iff it wasn't executed already.
     *
     * @param frame The frame the operation is executed on.
     * @param context The context of the search.
     * @return
     */
    bool execute(MatchingFrame& frame, const Matcher::ISearchContext& context) {
        _executed = _executed ? false : check(frame, context);
        return _executed;
    }

protected:
    /**
     * Defines the execution of the check operation.
     *
     * @param frame The frame the operation is executed on.
     * @param context The context of the search.
     * @return **True** if the check was successful, **False** otherwise.
     */
    virtual bool check(MatchingFrame& frame, const Matcher::ISearchContext& context) = 0;

private:
    bool _executed; /** @var Indicates whether the check was executed already. **/
};

}  // namespace Check
}  // namespace Operations
}  // namespace Localsearch

#endif /* LOCALSEARCH_OPERATIONS_CHECK_CHECKOPERATION_H_ */
