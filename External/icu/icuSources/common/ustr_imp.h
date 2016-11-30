/*  
**********************************************************************
*   Copyright (C) 1999-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
**********************************************************************
*   file name:  ustr_imp.h
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 2001jan30
*   created by: Markus W. Scherer
*/

#ifndef __USTR_IMP_H__
#define __USTR_IMP_H__

#include "unicode/utypes.h"
#include "unicode/uiter.h"
#include "ucase.h"

/** Simple declaration for u_strToTitle() to avoid including unicode/ubrk.h. */
#ifndef UBRK_TYPEDEF_UBREAK_ITERATOR
#   define UBRK_TYPEDEF_UBREAK_ITERATOR
    typedef void UBreakIterator;
#endif

/**
 * Compare two strings in code point order or code unit order.
 * Works in strcmp style (both lengths -1),
 * strncmp style (lengths equal and >=0, flag TRUE),
 * and memcmp/UnicodeString style (at least one length >=0).
 * @internal
 */
U_CAPI int32_t U_EXPORT2
uprv_strCompare(const UChar *s1, int32_t length1,
                const UChar *s2, int32_t length2,
                UBool strncmpStyle, UBool codePointOrder);

/**
 * Internal API, used by u_strcasecmp() etc.
 * Compare strings case-insensitively,
 * in code point order or code unit order.
 * @internal
 */
U_CFUNC int32_t
u_strcmpFold(const UChar *s1, int32_t length1,
             const UChar *s2, int32_t length2,
             uint32_t options,
             UErrorCode *pErrorCode);

/**
 * Are the Unicode properties loaded?
 * This must be used before internal functions are called that do
 * not perform this check.
 * Generate a debug assertion failure if data is not loaded, to flag the fact
 *   that u_init() wasn't called first, before trying to access character properties.
 * @internal
 */
U_CFUNC UBool
uprv_haveProperties(UErrorCode *pErrorCode);

/**
  * Load the Unicode property data.
  * Intended primarily for use from u_init().
  * Has no effect if property data is already loaded.
  * NOT thread safe.
  * @internal
  */
/*U_CFUNC int8_t
uprv_loadPropsData(UErrorCode *errorCode);*/

/**
 * Type of a function that may be passed to the internal case mapping functions
 * or similar for growing the destination buffer.
 * @internal
 */
typedef UBool U_CALLCONV
UGrowBuffer(void *context,      /* opaque pointer for this function */
            UChar **pBuffer,    /* in/out destination buffer pointer */
            int32_t *pCapacity, /* in/out buffer capacity in numbers of UChars */
            int32_t reqCapacity,/* requested capacity */
            int32_t length);    /* number of UChars to be copied to new buffer */

/**
 * Default implementation of UGrowBuffer.
 * Takes a static buffer as context, allocates a new buffer,
 * and releases the old one if it is not the same as the one passed as context.
 * @internal
 */
U_CAPI UBool /* U_CALLCONV U_EXPORT2 */
u_growBufferFromStatic(void *context,
                       UChar **pBuffer, int32_t *pCapacity, int32_t reqCapacity,
                       int32_t length);

/*
 * Internal string casing functions implementing
 * ustring.h/ustrcase.c and UnicodeString case mapping functions.
 */

/**
 * @internal
 */
U_CFUNC int32_t
ustr_toLower(const UCaseProps *csp,
             UChar *dest, int32_t destCapacity,
             const UChar *src, int32_t srcLength,
             const char *locale,
             UErrorCode *pErrorCode);

/**
 * @internal
 */
U_CFUNC int32_t
ustr_toUpper(const UCaseProps *csp,
             UChar *dest, int32_t destCapacity,
             const UChar *src, int32_t srcLength,
             const char *locale,
             UErrorCode *pErrorCode);

#if !UCONFIG_NO_BREAK_ITERATION

/**
 * @internal
 */
U_CFUNC int32_t
ustr_toTitle(const UCaseProps *csp,
             UChar *dest, int32_t destCapacity,
             const UChar *src, int32_t srcLength,
             UBreakIterator *titleIter,
             const char *locale,
             UErrorCode *pErrorCode);

#endif

/**
 * Internal case folding function.
 * @internal
 */
U_CFUNC int32_t
ustr_foldCase(const UCaseProps *csp,
              UChar *dest, int32_t destCapacity,
              const UChar *src, int32_t srcLength,
              uint32_t options,
              UErrorCode *pErrorCode);

/**
 * NUL-terminate a UChar * string if possible.
 * If length  < destCapacity then NUL-terminate.
 * If length == destCapacity then do not terminate but set U_STRING_NOT_TERMINATED_WARNING.
 * If length  > destCapacity then do not terminate but set U_BUFFER_OVERFLOW_ERROR.
 *
 * @param dest Destination buffer, can be NULL if destCapacity==0.
 * @param destCapacity Number of UChars available at dest.
 * @param length Number of UChars that were (to be) written to dest.
 * @param pErrorCode ICU error code.
 * @return length
 * @internal
 */
U_CAPI int32_t U_EXPORT2
u_terminateUChars(UChar *dest, int32_t destCapacity, int32_t length, UErrorCode *pErrorCode);

/**
 * NUL-terminate a char * string if possible.
 * Same as u_terminateUChars() but for a different string type.
 */
U_CAPI int32_t U_EXPORT2
u_terminateChars(char *dest, int32_t destCapacity, int32_t length, UErrorCode *pErrorCode);

/**
 * NUL-terminate a UChar32 * string if possible.
 * Same as u_terminateUChars() but for a different string type.
 */
U_CAPI int32_t U_EXPORT2
u_terminateUChar32s(UChar32 *dest, int32_t destCapacity, int32_t length, UErrorCode *pErrorCode);

/**
 * NUL-terminate a wchar_t * string if possible.
 * Same as u_terminateUChars() but for a different string type.
 */
U_CAPI int32_t U_EXPORT2
u_terminateWChars(wchar_t *dest, int32_t destCapacity, int32_t length, UErrorCode *pErrorCode);

#endif
