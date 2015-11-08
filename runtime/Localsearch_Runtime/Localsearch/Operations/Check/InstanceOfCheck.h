/*
 * InstanceOfCheck.h
 *
 *  Created on: Apr 16, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_OPERATIONS_CHECK_INSTANCEOFCHECK_H_
#define LOCALSEARCH_OPERATIONS_CHECK_INSTANCEOFCHECK_H_

#include <list>

#include "../../Matcher/ISearchContext.h"
#include "../../Util/Defs.h"
#include "../../Util/IClassHelper.h"
#include "CheckOperation.h"

namespace Localsearch {
namespace Operations {
namespace Check {

/**
 * @brief InstanceOf check.
 *
 * This type of check examines whether an instance is of the specified type.
 *
 * @tparam CheckedType The type of the checked object.
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename CheckedType, typename MatchingFrame>
class InstanceOfCheck: public CheckOperation<MatchingFrame> {
    typedef CheckedType MatchingFrame::* CheckedMember;
public:
    InstanceOfCheck(CheckedMember checked, XTClass clazz);

    bool check(MatchingFrame& frame, const Matcher::ISearchContext& context);

private:
    CheckedMember _checked;
    int _clazz;
};

template<typename CheckedType, typename MatchingFrame>
inline InstanceOfCheck<CheckedType, MatchingFrame>::InstanceOfCheck(CheckedMember checked, XTClass clazz) :
        _checked(checked), _clazz(clazz) {
}

template<typename CheckedType, typename MatchingFrame>
inline bool InstanceOfCheck<CheckedType, MatchingFrame>::check(MatchingFrame& frame,
        const Matcher::ISearchContext& context) {
    const Localsearch::Util::IClassHelper& ch = context.get_class_helper();
    const CheckedType checkedObject = frame.*_checked;
    return ch.is_super_type(checkedObject->get_type_id(), _clazz);
}

template<typename CheckedType, typename MatchingFrame>
inline InstanceOfCheck<CheckedType, MatchingFrame>* create_InstanceOfCheck(CheckedType MatchingFrame::* checked, XTClass clazz) {
	return new InstanceOfCheck<CheckedType, MatchingFrame>(checked, clazz);
}


}  // namespace Check
} /* namespace Util */
} /* namespace Localsearch */

#endif /* LOCALSEARCH_OPERATIONS_CHECK_INSTANCEOFCHECK_H_ */
