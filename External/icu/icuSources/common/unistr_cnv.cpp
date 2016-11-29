/*
*******************************************************************************
*
*   Copyright (C) 1999-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
*******************************************************************************
*   file name:  unistr_cnv.cpp
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:2
*
*   created on: 2004aug19
*   created by: Markus W. Scherer
*
*   Character conversion functions moved here from unistr.cpp
*/

#include "unicode/utypes.h"

#if !UCONFIG_NO_CONVERSION

#include "unicode/putil.h"
#include "cstring.h"
#include "cmemory.h"
#include "unicode/ustring.h"
#include "unicode/unistr.h"
#include "unicode/ucnv.h"
#include "putilimp.h"
#include "ustr_cnv.h"
#include "ustr_imp.h"

U_NAMESPACE_BEGIN

//========================================
// Constructors
//========================================

UnicodeString::UnicodeString(const char *codepageData,
                             const char *codepage)
  : fLength(0),
    fCapacity(US_STACKBUF_SIZE),
    fArray(fStackBuffer),
    fFlags(kShortString)
{
    if(codepageData != 0) {
        doCodepageCreate(codepageData, (int32_t)uprv_strlen(codepageData), codepage);
    }
}


UnicodeString::UnicodeString(const char *codepageData,
                             int32_t dataLength,
                             const char *codepage)
  : fLength(0),
    fCapacity(US_STACKBUF_SIZE),
    fArray(fStackBuffer),
    fFlags(kShortString)
{
    if(codepageData != 0) {
        doCodepageCreate(codepageData, dataLength, codepage);
    }
}

UnicodeString::UnicodeString(const char *src, int32_t srcLength,
                             UConverter *cnv,
                             UErrorCode &errorCode)
  : fLength(0),
    fCapacity(US_STACKBUF_SIZE),
    fArray(fStackBuffer),
    fFlags(kShortString)
{
    if(U_SUCCESS(errorCode)) {
        // check arguments
        if(src==NULL) {
            // treat as an empty string, do nothing more
        } else if(srcLength<-1) {
            errorCode=U_ILLEGAL_ARGUMENT_ERROR;
        } else {
            // get input length
            if(srcLength==-1) {
                srcLength=(int32_t)uprv_strlen(src);
            }
            if(srcLength>0) {
                if(cnv!=0) {
                    // use the provided converter
                    ucnv_resetToUnicode(cnv);
                    doCodepageCreate(src, srcLength, cnv, errorCode);
                } else {
                    // use the default converter
                    cnv=u_getDefaultConverter(&errorCode);
                    doCodepageCreate(src, srcLength, cnv, errorCode);
                    u_releaseDefaultConverter(cnv);
                }
            }
        }

        if(U_FAILURE(errorCode)) {
            setToBogus();
        }
    }
}

//========================================
// Codeset conversion
//========================================
int32_t
UnicodeString::extract(int32_t start,
                       int32_t length,
                       char *target,
                       uint32_t dstSize,
                       const char *codepage) const
{
    // if the arguments are illegal, then do nothing
    if(/*dstSize < 0 || */(dstSize > 0 && target == 0)) {
        return 0;
    }

    // pin the indices to legal values
    pinIndices(start, length);

    // create the converter
    UConverter *converter;
    UErrorCode status = U_ZERO_ERROR;

    // just write the NUL if the string length is 0
    if(length == 0) {
        if(dstSize >= 0x80000000) {  
            // careful: dstSize is unsigned! (0xffffffff means "unlimited")
            // make sure that the NUL-termination works (takes int32_t)
            dstSize=0x7fffffff;
        }
        return u_terminateChars(target, dstSize, 0, &status);
    }

    // if the codepage is the default, use our cache
    // if it is an empty string, then use the "invariant character" conversion
    if (codepage == 0) {
        converter = u_getDefaultConverter(&status);
    } else if (*codepage == 0) {
        // use the "invariant characters" conversion
        int32_t destLength;
        // careful: dstSize is unsigned! (0xffffffff means "unlimited")
        if(dstSize >= 0x80000000) {
            destLength = length;
            // make sure that the NUL-termination works (takes int32_t)
            dstSize=0x7fffffff;
        } else if(length <= (int32_t)dstSize) {
            destLength = length;
        } else {
            destLength = (int32_t)dstSize;
        }
        u_UCharsToChars(getArrayStart() + start, target, destLength);
        return u_terminateChars(target, (int32_t)dstSize, length, &status);
    } else {
        converter = ucnv_open(codepage, &status);
    }

    length = doExtract(start, length, target, (int32_t)dstSize, converter, status);

    // close the converter
    if (codepage == 0) {
        u_releaseDefaultConverter(converter);
    } else {
        ucnv_close(converter);
    }

    return length;
}

int32_t
UnicodeString::extract(char *dest, int32_t destCapacity,
                       UConverter *cnv,
                       UErrorCode &errorCode) const
{
    if(U_FAILURE(errorCode)) {
        return 0;
    }

    if(isBogus() || destCapacity<0 || (destCapacity>0 && dest==0)) {
        errorCode=U_ILLEGAL_ARGUMENT_ERROR;
        return 0;
    }

    // nothing to do?
    if(fLength<=0) {
        return u_terminateChars(dest, destCapacity, 0, &errorCode);
    }

    // get the converter
    UBool isDefaultConverter;
    if(cnv==0) {
        isDefaultConverter=TRUE;
        cnv=u_getDefaultConverter(&errorCode);
        if(U_FAILURE(errorCode)) {
            return 0;
        }
    } else {
        isDefaultConverter=FALSE;
        ucnv_resetFromUnicode(cnv);
    }

    // convert
    int32_t length=doExtract(0, fLength, dest, destCapacity, cnv, errorCode);

    // release the converter
    if(isDefaultConverter) {
        u_releaseDefaultConverter(cnv);
    }

    return length;
}

int32_t
UnicodeString::doExtract(int32_t start, int32_t length,
                         char *dest, int32_t destCapacity,
                         UConverter *cnv,
                         UErrorCode &errorCode) const
{
    if(U_FAILURE(errorCode)) {
        if(destCapacity!=0) {
            *dest=0;
        }
        return 0;
    }

    const UChar *src=fArray+start, *srcLimit=src+length;
    char *originalDest=dest;
    const char *destLimit;

    if(destCapacity==0) {
        destLimit=dest=0;
    } else if(destCapacity==-1) {
        // Pin the limit to U_MAX_PTR if the "magic" destCapacity is used.
        destLimit=(char*)U_MAX_PTR(dest);
        // for NUL-termination, translate into highest int32_t
        destCapacity=0x7fffffff;
    } else {
        destLimit=dest+destCapacity;
    }

    // perform the conversion
    ucnv_fromUnicode(cnv, &dest, destLimit, &src, srcLimit, 0, TRUE, &errorCode);
    length=(int32_t)(dest-originalDest);

    // if an overflow occurs, then get the preflighting length
    if(errorCode==U_BUFFER_OVERFLOW_ERROR) {
        char buffer[1024];

        destLimit=buffer+sizeof(buffer);
        do {
            dest=buffer;
            errorCode=U_ZERO_ERROR;
            ucnv_fromUnicode(cnv, &dest, destLimit, &src, srcLimit, 0, TRUE, &errorCode);
            length+=(int32_t)(dest-buffer);
        } while(errorCode==U_BUFFER_OVERFLOW_ERROR);
    }

    return u_terminateChars(originalDest, destCapacity, length, &errorCode);
}

void
UnicodeString::doCodepageCreate(const char *codepageData,
                                int32_t dataLength,
                                const char *codepage)
{
    // if there's nothing to convert, do nothing
    if(codepageData == 0 || dataLength == 0 || dataLength < -1) {
        return;
    }
    if(dataLength == -1) {
        dataLength = (int32_t)uprv_strlen(codepageData);
    }

    UErrorCode status = U_ZERO_ERROR;

    // create the converter
    // if the codepage is the default, use our cache
    // if it is an empty string, then use the "invariant character" conversion
    UConverter *converter = (codepage == 0 ?
                             u_getDefaultConverter(&status) :
                             *codepage == 0 ?
                               0 :
                               ucnv_open(codepage, &status));

    // if we failed, set the appropriate flags and return
    if(U_FAILURE(status)) {
        setToBogus();
        return;
    }

    // perform the conversion
    if(converter == 0) {
        // use the "invariant characters" conversion
        if(cloneArrayIfNeeded(dataLength, dataLength, FALSE)) {
            u_charsToUChars(codepageData, getArrayStart(), dataLength);
            fLength = dataLength;
        } else {
            setToBogus();
        }
        return;
    }

    // convert using the real converter
    doCodepageCreate(codepageData, dataLength, converter, status);
    if(U_FAILURE(status)) {
        setToBogus();
    }

    // close the converter
    if(codepage == 0) {
        u_releaseDefaultConverter(converter);
    } else {
        ucnv_close(converter);
    }
}

void
UnicodeString::doCodepageCreate(const char *codepageData,
                                int32_t dataLength,
                                UConverter *converter,
                                UErrorCode &status)
{
    if(U_FAILURE(status)) {
        return;
    }

    // set up the conversion parameters
    const char *mySource     = codepageData;
    const char *mySourceEnd  = mySource + dataLength;
    UChar *myTarget;

    // estimate the size needed:
    // 1.25 UChar's per source byte should cover most cases
    int32_t arraySize = dataLength + (dataLength >> 2);

    // we do not care about the current contents
    UBool doCopyArray = FALSE;
    for(;;) {
        if(!cloneArrayIfNeeded(arraySize, arraySize, doCopyArray)) {
            setToBogus();
            break;
        }

        // perform the conversion
        myTarget = fArray + fLength;
        ucnv_toUnicode(converter, &myTarget,  fArray + fCapacity,
            &mySource, mySourceEnd, 0, TRUE, &status);

        // update the conversion parameters
        fLength = (int32_t)(myTarget - fArray);

        // allocate more space and copy data, if needed
        if(status == U_BUFFER_OVERFLOW_ERROR) {
            // reset the error code
            status = U_ZERO_ERROR;

            // keep the previous conversion results
            doCopyArray = TRUE;

            // estimate the new size needed, larger than before
            // try 2 UChar's per remaining source byte
            arraySize = (int32_t)(fLength + 2 * (mySourceEnd - mySource));
        } else {
            break;
        }
    }
}

U_NAMESPACE_END

#endif
