/*
*******************************************************************************
*
*   Copyright (C) 2004-2005, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
*******************************************************************************
*   file name:  uset_imp.h
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 2004sep07
*   created by: Markus W. Scherer
*
*   Internal USet definitions.
*/

#ifndef __USET_IMP_H__
#define __USET_IMP_H__

#include "unicode/utypes.h"
#include "unicode/uset.h"

U_CDECL_BEGIN

typedef void U_CALLCONV
USetAdd(USet *set, UChar32 c);

typedef void U_CALLCONV
USetAddRange(USet *set, UChar32 start, UChar32 end);

typedef void U_CALLCONV
USetAddString(USet *set, const UChar *str, int32_t length);

typedef void U_CALLCONV
USetRemove(USet *set, UChar32 c);

/**
 * Interface for adding items to a USet, to keep low-level code from
 * statically depending on the USet implementation.
 * Calls will look like sa->add(sa->set, c);
 */
struct USetAdder {
    USet *set;
    USetAdd *add;
    USetAddRange *addRange;
    USetAddString *addString;
    USetRemove *remove;
};
typedef struct USetAdder USetAdder;

U_CDECL_END

/**
 * Get the set of "white space" characters in the sense of ICU rule
 * parsers.  Caller must close/delete result.
 * Equivalent to the set of characters with the Pattern_White_Space Unicode property.
 * Stable set of characters, won't change.
 * See UAX #31 Identifier and Pattern Syntax: http://www.unicode.org/reports/tr31/
 * @internal
 */
U_CAPI USet* U_EXPORT2
uprv_openRuleWhiteSpaceSet(UErrorCode* ec);

#endif

