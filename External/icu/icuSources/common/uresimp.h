/*
**********************************************************************
*   Copyright (C) 2000-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
**********************************************************************
*/

#ifndef URESIMP_H
#define URESIMP_H

#include "unicode/ures.h"

#include "uresdata.h"

#define kRootLocaleName         "root"

/*
 The default minor version and the version separator must be exactly one
 character long.
*/

#define kDefaultMinorVersion    "0"
#define kVersionSeparator       "."
#define kVersionTag             "Version"

#define MAGIC1 19700503
#define MAGIC2 19641227

#define URES_MAX_ALIAS_LEVEL 256
#define URES_MAX_BUFFER_SIZE 256

/*
enum UResEntryType {
    ENTRY_OK = 0,
    ENTRY_GOTO_ROOT = 1,
    ENTRY_GOTO_DEFAULT = 2,
    ENTRY_INVALID = 3
};

typedef enum UResEntryType UResEntryType;
*/

struct UResourceDataEntry;
typedef struct UResourceDataEntry UResourceDataEntry;

struct UResourceDataEntry {
    char *fName; /* name of the locale for bundle - still to decide whether it is original or fallback */
    char *fPath; /* path to bundle - used for distinguishing between resources with the same name */
    uint32_t fCountExisting; /* how much is this resource used */
    ResourceData fData; /* data for low level access */
    UResourceDataEntry *fParent; /*next resource in fallback chain*/
/*    UResEntryType fStatus;*/
    UErrorCode fBogus;
    int32_t fHashKey; /* for faster access in the hashtable */
};

#define RES_BUFSIZE 64
#define RES_PATH_SEPARATOR   '/'
#define RES_PATH_SEPARATOR_S   "/"

struct UResourceBundle {
    const char *fKey; /*tag*/
    UResourceDataEntry *fData; /*for low-level access*/
    char *fVersion;
    char *fResPath; /* full path to the resource: "zh_TW/CollationElements/Sequence" */
    char fResBuf[RES_BUFSIZE];
    int32_t fResPathLen;
    UBool fHasFallback;
    UBool fIsTopLevel;
    uint32_t fMagic1;   /* For determining if it's a stack object */
    uint32_t fMagic2;   /* For determining if it's a stack object */
    int32_t fIndex;
    int32_t fSize;
    ResourceData fResData;
    Resource fRes;

    UResourceDataEntry *fTopLevelData; /* for getting the valid locale */
    const UResourceBundle *fParentRes; /* needed to get the actual locale for a child resource */

};

U_CAPI void U_EXPORT2 ures_initStackObject(UResourceBundle* resB);

/* Some getters used by the copy constructor */
U_CFUNC const char* ures_getName(const UResourceBundle* resB);
U_CFUNC const char* ures_getPath(const UResourceBundle* resB);
/*U_CFUNC void ures_appendResPath(UResourceBundle *resB, const char* toAdd, int32_t lenToAdd);*/
/*U_CFUNC void ures_setResPath(UResourceBundle *resB, const char* toAdd);*/
/*U_CFUNC void ures_freeResPath(UResourceBundle *resB);*/

/* Candidates for export */
U_CFUNC UResourceBundle *ures_copyResb(UResourceBundle *r, const UResourceBundle *original, UErrorCode *status);

/**
 * Returns a resource that can be located using the pathToResource argument. One needs optional package, locale
 * and path inside the locale, for example: "/myData/en/zoneStrings/3". Keys and indexes are supported. Keys
 * need to reference data in named structures, while indexes can reference both named and anonymous resources.
 * Features a fill-in parameter. 
 * 
 * Note, this function does NOT have a syntax for specifying items within a tree.  May want to consider a
 * syntax that delineates between package/tree and resource.  
 *
 * @param pathToResource    a path that will lead to the requested resource
 * @param fillIn            if NULL a new UResourceBundle struct is allocated and must be deleted by the caller.
 *                          Alternatively, you can supply a struct to be filled by this function.
 * @param status            fills in the outgoing error code.
 * @return                  a pointer to a UResourceBundle struct. If fill in param was NULL, caller must delete it
 * @draft ICU 2.2
 */
U_CAPI UResourceBundle* U_EXPORT2
ures_findResource(const char* pathToResource, 
                  UResourceBundle *fillIn, UErrorCode *status); 

/**
 * Returns a sub resource that can be located using the pathToResource argument. One needs a path inside 
 * the supplied resource, for example, if you have "en_US" resource bundle opened, you might ask for
 * "zoneStrings/3". Keys and indexes are supported. Keys
 * need to reference data in named structures, while indexes can reference both 
 * named and anonymous resources.
 * Features a fill-in parameter. 
 *
 * @param resourceBundle    a resource
 * @param pathToResource    a path that will lead to the requested resource
 * @param fillIn            if NULL a new UResourceBundle struct is allocated and must be deleted by the caller.
 *                          Alternatively, you can supply a struct to be filled by this function.
 * @param status            fills in the outgoing error code.
 * @return                  a pointer to a UResourceBundle struct. If fill in param was NULL, caller must delete it
 * @draft ICU 2.2
 */
U_CAPI UResourceBundle* U_EXPORT2
ures_findSubResource(const UResourceBundle *resB, 
                     char* pathToResource, 
                     UResourceBundle *fillIn, UErrorCode *status);

/**
 * Returns a functionally equivalent locale (considering keywords) for the specified keyword.
 * @param result fillin for the equivalent locale
 * @param resultCapacity capacity of the fillin buffer
 * @param path path to the tree, or NULL for ICU data
 * @param resName top level resource. Example: "collations"
 * @param keyword locale keyword. Example: "collation"
 * @param locid The requested locale
 * @param isAvailable If non-null, pointer to fillin parameter that indicates whether the 
 * requested locale was available. The locale is defined as 'available' if it physically 
 * exists within the specified tree.
 * @param omitDefault if TRUE, omit keyword and value if default. 'de_DE\@collation=standard' -> 'de_DE'
 * @param status error code
 * @return  the actual buffer size needed for the full locale.  If it's greater 
 * than resultCapacity, the returned full name will be truncated and an error code will be returned.
 * @internal ICU 3.0
 */
U_INTERNAL int32_t U_EXPORT2
ures_getFunctionalEquivalent(char *result, int32_t resultCapacity, 
                             const char *path, const char *resName, const char *keyword, const char *locid,
                             UBool *isAvailable, UBool omitDefault, UErrorCode *status);

/**
 * Given a tree path and keyword, return a string enumeration of all possible values for that keyword.
 * @param path path to the tree, or NULL for ICU data
 * @param keyword a particular keyword to consider, must match a top level resource name 
 * within the tree.
 * @param status error code
 * @internal ICU 3.0
 */
U_INTERNAL UEnumeration* U_EXPORT2
ures_getKeywordValues(const char *path, const char *keyword, UErrorCode *status);

/**
 * Test if 2 resource bundles are equal
 * @param res1
 * @param res2
 * @param status error code
 * @internal ICU 3.6
 */
U_INTERNAL UBool U_EXPORT2
ures_equal(const UResourceBundle* res1, const UResourceBundle* res2);

/**
 * Clones the given resource bundle
 * @param res
 * @param status error code
 * @internal ICU 3.6
 */
U_INTERNAL UResourceBundle* U_EXPORT2
ures_clone(const UResourceBundle* res, UErrorCode* status);

/**
 * Returns the parent bundle. Internal. DONOT close the returned bundle!!!
 * @param res
 * @internal ICU 3.6
 */
U_INTERNAL const UResourceBundle* U_EXPORT2
ures_getParentBundle(const UResourceBundle* res);


/**
 * Get a resource with multi-level fallback. Normally only the top level resources will
 * fallback to its parent. This performs fallback on subresources. For example, when a table
 * is defined in a resource bundle and a parent resource bundle, normally no fallback occurs
 * on the sub-resources because the table is defined in the current resource bundle, but this
 * function can perform fallback on the sub-resources of the table.
 * @param resB              a resource
 * @param inKey             a key associated with the requested resource
 * @param fillIn            if NULL a new UResourceBundle struct is allocated and must be deleted by the caller.
 *                          Alternatively, you can supply a struct to be filled by this function.
 * @param status: fills in the outgoing error code
 *                could be <TT>U_MISSING_RESOURCE_ERROR</TT> if the key is not found
 *                could be a non-failing error 
 *                e.g.: <TT>U_USING_FALLBACK_WARNING</TT>,<TT>U_USING_DEFAULT_WARNING </TT>
 * @return                  a pointer to a UResourceBundle struct. If fill in param was NULL, caller must delete it
 * @internal ICU 3.0
 */
U_INTERNAL UResourceBundle* U_EXPORT2 
ures_getByKeyWithFallback(const UResourceBundle *resB, 
                          const char* inKey, 
                          UResourceBundle *fillIn, 
                          UErrorCode *status);


/**
 * Get a String with multi-level fallback. Normally only the top level resources will
 * fallback to its parent. This performs fallback on subresources. For example, when a table
 * is defined in a resource bundle and a parent resource bundle, normally no fallback occurs
 * on the sub-resources because the table is defined in the current resource bundle, but this
 * function can perform fallback on the sub-resources of the table.
 * @param resB              a resource
 * @param inKey             a key associated with the requested resource
 * @param status: fills in the outgoing error code
 *                could be <TT>U_MISSING_RESOURCE_ERROR</TT> if the key is not found
 *                could be a non-failing error 
 *                e.g.: <TT>U_USING_FALLBACK_WARNING</TT>,<TT>U_USING_DEFAULT_WARNING </TT>
 * @return                  a pointer to a UResourceBundle struct. If fill in param was NULL, caller must delete it
 * @internal ICU 3.4
 * @draft ICU 3.4
 */
U_INTERNAL const UChar* U_EXPORT2 
ures_getStringByKeyWithFallback(const UResourceBundle *resB, 
                          const char* inKey,  
                          int32_t* len,
                          UErrorCode *status);
#endif /*URESIMP_H*/
