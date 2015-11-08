/*
 * ISearchContext.h
 *
 *  Created on: Apr 16, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_MATCHER_ISEARCHCONTEXT_H_
#define LOCALSEARCH_MATCHER_ISEARCHCONTEXT_H_

#include "../Util/IClassHelper.h"

namespace Localsearch {
namespace Matcher {

/**
 * @brief Context of the search.
 *
 * An instance of this class represents the context of a search,
 * giving access to a collection of utility classes that can be
 * used while searching for a pattern.
 *
 * For now it only contains the Util::IClassHelper, but it might get extended later.
 */
class ISearchContext {
public:
    /**
     * Constructs an instance of ISearchContext wit the specified instance
     * of Util::IClassHelper.
     *
     * @param ch The pointer to the instance of an Util::IClassHelper.
     */
    ISearchContext(Util::IClassHelper* ch) :
            _ch(ch) {
    }

    /**
     * Returns an instance of Util::IClassHelper.
     *
     * @return The instance of Util::IClassHelper.
     */
    Util::IClassHelper& get_class_helper() const {
        return *_ch;
    }

private:
    Util::IClassHelper* _ch;
};

}  // namespace Matcher
}  // namespace Localsearch

#endif /* LOCALSEARCH_MATCHER_ISEARCHCONTEXT_H_ */
