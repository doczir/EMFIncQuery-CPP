/*
 * IClassHelper.h
 *
 *  Created on: Apr 18, 2015
 *      Author: Robert Doczi
 */

#ifndef LOCALSEARCH_UTIL_ICLASSHELPER_H_
#define LOCALSEARCH_UTIL_ICLASSHELPER_H_

#include "Defs.h"

namespace Localsearch {
namespace Util {

/**
 * @brief Interface of a class helper.
 *
 * This is an interface for different implementation of class helpers for inheritance checking.
 */
class IClassHelper {
public:
    virtual ~IClassHelper() {
    }

    /**
     * Checks whether parent is the super type of child.
     *
     * @param child The child type.
     * @param parent The super type.
     *
     * @return **True** if parent is super of child, **False** otherwise.
     */
    virtual bool is_super_type(const XTClass& child, const XTClass& parent) const = 0;
};

}  // namespace Util
}  // namespace Localsearch

#endif /* LOCALSEARCH_UTIL_ICLASSHELPER_H_ */
