/*
 * NavigateAssociation.h
 *
 *  Created on: May 8, 2015
 *      Author: doczir
 */

#ifndef LOCALSEARCH_OPERATIONS_EXTEND_NAVIGATEASSOCIATION_H_
#define LOCALSEARCH_OPERATIONS_EXTEND_NAVIGATEASSOCIATION_H_

#include <string>
#include <list>

#include "ExtendOperation.h"

namespace Localsearch {
namespace Operations {
namespace Extend {

/**
 * @brief Association navigation for [0, 1] multiplicity.
 *
 * This extend operation navigates to the end of an association from the source already bound in the
 * frame and binds the value found there. This is only usable, iff the multiplicity of the association
 * end is [0, 1], since this check presumes the target is single value.
 *
 * @tparam SrcType The type of the source object.
 * @tparam TrgType The type of the target object.
 * @tparam Member The type the src has to be so the navigation can happen.
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename SrcType, typename TrgType, typename Member, typename MatchingFrame>
class NavigateSingleAssociation: public ExtendOperation<TrgType, std::list<TrgType>, MatchingFrame> {
	typedef SrcType MatchingFrame::* SrcGetter; /** @typedef The type of the member pointer for getting the source from the frame. */
	typedef TrgType MatchingFrame::* MemberToBind; /** @typedef The type of the member pointer used to bind a value in a frame */
	typedef TrgType Member::* Navigator; /** @typedef The type of the member pointer for navigating from source to target. */
public:
    NavigateSingleAssociation(SrcGetter getSrc, MemberToBind bindMember, Navigator navigate);
    void on_initialize(MatchingFrame& frame, const Matcher::ISearchContext& context);

private:
    SrcGetter _getSrc;
    Navigator _navigate;
    std::list<TrgType> _objectHolder;
};


/**
 * @brief Association check for [0, *] multiplicity.
 *
 * This extend operation navigates to the end of an association from the source already bound in the
 * frame and binds the value found there. This is only usable, iff the multiplicity of the association
 * end is [0, *], since this check presumes the target is a collection of values.
 *
 * @tparam SrcType The type of the source object.
 * @tparam TrgType The type of the target object.
 * @tparam Collection The type of the collection containing the instances of targets.
 * @tparam MatchingFrame Describes the structure of the *MatchingFrame* the operation is executed on.
 */
template<typename SrcType, typename TrgType, typename Collection, typename Member, typename MatchingFrame>
class NavigateMultiAssociation: public ExtendOperation<TrgType, Collection, MatchingFrame> {
	typedef SrcType MatchingFrame::* SrcGetter; /** @typedef The type of the member pointer for getting the source from the frame. */
	typedef TrgType MatchingFrame::* MemberToBind; /** @typedef The type of the member pointer used to bind a value in a frame */
	typedef Collection Member::* Navigator; /** @typedef The type of the member pointer for navigating from source to target. */
public:
    NavigateMultiAssociation(SrcGetter getSrc, MemberToBind bindMember, Navigator navigate);
    void on_initialize(MatchingFrame& frame, const Matcher::ISearchContext& context);

private:
    SrcGetter _getSrc;
    Navigator _navigate;
};

template<typename SrcType, typename TrgType, typename Member, typename MatchingFrame>
inline NavigateSingleAssociation<SrcType, TrgType, Member, MatchingFrame>::NavigateSingleAssociation(SrcGetter getSrc, MemberToBind bindMember, Navigator navigate) :
        ExtendOperation<TrgType, std::list<TrgType>, MatchingFrame>(bindMember), _getSrc(getSrc), _navigate(navigate) {
}

template<typename SrcType, typename TrgType, typename Member, typename MatchingFrame>
inline void NavigateSingleAssociation<SrcType, TrgType, Member, MatchingFrame>::on_initialize(MatchingFrame& frame,
        const Matcher::ISearchContext&) {
    _objectHolder.clear();
    _objectHolder.push_back(static_cast<Member*>(frame.*_getSrc)->*_navigate);
    ExtendOperation<TrgType, std::list<TrgType>, MatchingFrame>::set_data(_objectHolder.begin(), _objectHolder.end());
}

template<typename SrcType, typename TrgType, typename Collection, typename Member, typename MatchingFrame>
inline NavigateMultiAssociation<SrcType, TrgType, Collection, Member, MatchingFrame>::NavigateMultiAssociation(SrcGetter getSrc,
		MemberToBind bindMember, Navigator navigate) :
        ExtendOperation<TrgType, Collection, MatchingFrame>(bindMember), _getSrc(getSrc), _navigate(navigate) {
}

template<typename SrcType, typename TrgType, typename Collection, typename Member, typename MatchingFrame>
inline void NavigateMultiAssociation<SrcType, TrgType, Collection, Member, MatchingFrame>::on_initialize(MatchingFrame& frame,
        const Matcher::ISearchContext&) {
    const Collection& data = static_cast<Member*>(frame.*_getSrc)->*_navigate;
    ExtendOperation<TrgType, Collection, MatchingFrame>::set_data(data.begin(), data.end());
}

template<typename SrcType, typename TrgType, typename Member, typename MatchingFrame>
inline NavigateSingleAssociation<SrcType, TrgType, Member, MatchingFrame>* create_NavigateSingleAssociation(SrcType MatchingFrame::* getSrc, TrgType MatchingFrame::* bindMember, TrgType Member::* navigate) {
	return new NavigateSingleAssociation<SrcType, TrgType, Member, MatchingFrame>(getSrc, bindMember, navigate);
}

template<typename SrcType, typename TrgType, typename Collection, typename Member, typename MatchingFrame>
inline NavigateMultiAssociation<SrcType, TrgType, Collection, Member, MatchingFrame>* create_NavigateMultiAssociation(SrcType MatchingFrame::* getSrc, TrgType MatchingFrame::* bindMember, Collection Member::* navigate) {
	return new NavigateMultiAssociation<SrcType, TrgType, Collection, Member, MatchingFrame>(getSrc, bindMember, navigate);
}

} /* namespace Extend */
} /* namespace Operations */
} /* namespace Localsearch */

#endif /* LOCALSEARCH_OPERATIONS_EXTEND_NAVIGATEASSOCIATION_H_ */
