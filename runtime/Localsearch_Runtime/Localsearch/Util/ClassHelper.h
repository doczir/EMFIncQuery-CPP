#ifndef LOCALSEARCH_UTIL_CLASSHELPER_H_
#define LOCALSEARCH_UTIL_CLASSHELPER_H_

#include <stddef.h>
#include <map>
#include <set>
#include <list>

#include "IClassHelper.h"
#include "Defs.h"

namespace Localsearch {
namespace Util {

/**
 * @brief Helper for tracking class inheritance.
 *
 * This class helps keep track of inheritance relationships using an inheritance matrix.
 * For example if the inheritance is as follows:
 *
 * @dot
 * digraph inheritance {
 *  node [shape=record, fontname=Helvetica, fontsize=10 ];
 *  Foo [ label="class Foo" ];
 *  Bar [ label="class Bar" ];
 *  SpecFoo [ label="class SpecFoo" ];
 *  SpecFoo -> Foo [ arrowhead="empty", style="solid" ];
 * }
 * @enddot
 *
 * the inheritance matrix will look like this:
 * |    -      |    Foo    |    Bar    | SpecFoo  |
 * |-----------|-----------|-----------|----------|
 * |    Foo    |   true    |   false   |   false  |
 * |    Bar    |   false   |   true    |   false  |
 * | SpecFoo   |   true    |   false   |   true   |
 */
class ClassHelper: public IClassHelper {
public:
    bool is_super_type(const XTClass& child, const XTClass& parent) const;

    /**
     * Builder for creating the inheritance matrix for the ClassHelper.
     */
    class ClassHelperBuilder {
    public:

        /**
         * Create the actual ClassHelper instance.
         * @return The ClassHelper instance.
         */
        IClassHelper* build();

        /**
         * Sets the currently configured type.
         *
         * @param current The type to be configured.
         *
         * @return The builder instance.
         */
        ClassHelperBuilder& forClass(XTClass current);

        /**
         * Sets the current type to have no super type.
         *
         * @return The builder instance.
         */
        ClassHelperBuilder& noSuper();

        /**
         * Sets the specified type to be the super type of the current type.
         *
         * @param super The super type.
         *
         * @return The builder instance.
         */
        ClassHelperBuilder& setSuper(XTClass super);

        /**
         * Sets the specified types to be the super type of the current type.
         *
         * @param super A list of types.
         *
         * @return The builder instance.
         */
        ClassHelperBuilder& setSuper(const std::list<XTClass>& super);

        friend class ClassHelper;

    private:
        ClassHelperBuilder();

        std::map<XTClass, std::set<XTClass> > _classRelationshipMap;
        int _current;
    };

    /**
     * Creates a builder instance.
     *
     * @return The builder instance.
     */
    static ClassHelperBuilder builder();

private:
    ClassHelper(std::map<XTClass, std::map<XTClass, bool> > inheritanceMatrix);

    std::map<XTClass, std::map<XTClass, bool> > _inheritanceMatrix;
};

} /* namespace Util */
} /* namespace Localsearch */

#endif /* LOCALSEARCH_UTIL_CLASSHELPER_H_ */
