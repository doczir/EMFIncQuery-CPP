/*
 * ClassHelper.cpp
 *
 *  Created on: Apr 18, 2015
 *      Author: Robert Doczi
 */

#include "ClassHelper.h"

#include <cstddef>

namespace Localsearch {
namespace Util {

using namespace std;

bool ClassHelper::is_super_type(const XTClass& child, const XTClass& parent) const {
    return (*(*_inheritanceMatrix.find(child)).second.find(parent)).second;
}

IClassHelper* ClassHelper::ClassHelperBuilder::build() {
    size_t nrOfClasses = _classRelationshipMap.size();
    std::map<XTClass, std::map<XTClass, bool> > inheritanceMatrix;
    for (size_t i = 0; i < nrOfClasses; i++) {
        for (size_t j = 0; j < nrOfClasses; j++) {
            if (i == j) {
                inheritanceMatrix[i][j] = true;
            } else {
                set<XTClass> currentClassParents = _classRelationshipMap[i];
                inheritanceMatrix[i][j] = currentClassParents.find(j) != currentClassParents.end();
            }
        }
    }
    return new ClassHelper(inheritanceMatrix);
}

ClassHelper::ClassHelperBuilder& ClassHelper::ClassHelperBuilder::forClass(XTClass current) {
    _current = current;
    return *this;
}

ClassHelper::ClassHelperBuilder& ClassHelper::ClassHelperBuilder::noSuper() {
    _classRelationshipMap[_current];
    return *this;
}

ClassHelper::ClassHelperBuilder& ClassHelper::ClassHelperBuilder::setSuper(XTClass super) {
    _classRelationshipMap[_current].insert(super);
    return *this;
}

ClassHelper::ClassHelperBuilder& ClassHelper::ClassHelperBuilder::setSuper(const list<XTClass>& super) {
    _classRelationshipMap[_current].insert(super.begin(), super.end());
    return *this;
}

ClassHelper::ClassHelperBuilder::ClassHelperBuilder() :
        _current(0) {
}

ClassHelper::ClassHelperBuilder ClassHelper::builder() {
    return ClassHelperBuilder();
}

ClassHelper::ClassHelper(std::map<XTClass, std::map<XTClass, bool> > inheritanceMatrix) :
        _inheritanceMatrix(inheritanceMatrix) {
}

} /* namespace Util */
} /* namespace Localsearch */

