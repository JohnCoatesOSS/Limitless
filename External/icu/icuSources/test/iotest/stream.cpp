/*
**********************************************************************
*   Copyright (C) 2002-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
**********************************************************************
*   file name:  iotest.cpp
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 2002feb21
*   created by: George Rhoten
*/


#include "unicode/ustream.h"

#include "unicode/ucnv.h"
#include "unicode/ustring.h"
#include "ustr_cnv.h"
#include "iotest.h"

#if U_IOSTREAM_SOURCE >= 199711
#if defined(__GNUC__) && __GNUC__ >= 4
#define USE_SSTREAM 1
#include <sstream>
#else
// <strstream> is deprecated on some platforms, and the compiler complains very loudly if you use it.
#include <strstream>
#endif
using namespace std;
#elif U_IOSTREAM_SOURCE >= 198506
#include <strstream.h>
#endif

#include <string.h>

U_CDECL_BEGIN
#ifdef U_WINDOWS
const UChar NEW_LINE[] = {0x0d,0x0a,0};
const char C_NEW_LINE[] = {0x0d,0x0a,0};
#define UTF8_NEW_LINE "\x0d\x0a"
#else
const UChar NEW_LINE[] = {0x0a,0};
const char C_NEW_LINE[] = {'\n',0};
#define UTF8_NEW_LINE "\x0a"
#endif
U_CDECL_END

U_CDECL_BEGIN
static void U_CALLCONV TestStream(void)
{
#if U_IOSTREAM_SOURCE >= 198506
    const UChar thisMu[] = { 0x74, 0x48, 0x69, 0x73, 0x3BC, 0};
    const UChar mu[] = { 0x6D, 0x75, 0};
    UnicodeString str1 = UNICODE_STRING_SIMPLE("str1");
    UnicodeString str2 = UNICODE_STRING_SIMPLE(" <<");
    UnicodeString str3 = UNICODE_STRING_SIMPLE("2");
    UnicodeString str4 = UNICODE_STRING_SIMPLE(" UTF-8 ");
    UnicodeString inStr = UNICODE_STRING_SIMPLE(" UTF-8 ");
    UnicodeString inStr2;
    char defConvName[UCNV_MAX_CONVERTER_NAME_LENGTH*2];
    char inStrC[128];
    UErrorCode status = U_ZERO_ERROR;
    UConverter *defConv;
    static const char testStr[] = "\x42\x65\x67\x69\x6E\x6E\x69\x6E\x67\x20\x6F\x66\x20\x74\x65\x73\x74\x20\x73\x74\x72\x31\x20\x20\x20\x3C\x3C\x32\x31\x20" UTF8_NEW_LINE "\x20\x55\x54\x46\x2D\x38\x20\xCE\xBC\xF0\x90\x80\x81\xF0\x90\x80\x82";

    str4.append((UChar32)0x03BC);   /* mu */
    str4.append((UChar32)0x10001);
    str4.append((UChar32)0x10002);

    /* release the default converter and use utf-8 for a bit */
    defConv = u_getDefaultConverter(&status);
    if (U_FAILURE(status)) {
        log_err("Can't get default converter\n");
        return;
    }
    ucnv_close(defConv);
    strncpy(defConvName, ucnv_getDefaultName(), sizeof(defConvName)/sizeof(defConvName[0]));
    ucnv_setDefaultName("UTF-8");

    static const char * const TESTSTRING = "\x20\x74\x48\x69\x73\xCE\xBC\xE2\x80\x82\x20\x6D\x75\x20\x77\x6F\x72\x6C\x64";
#ifdef USE_SSTREAM
    ostringstream outTestStream;
    istringstream inTestStream(TESTSTRING);
#else
    char testStreamBuf[512];
    ostrstream outTestStream(testStreamBuf, sizeof(testStreamBuf));
    istrstream inTestStream(TESTSTRING, 0);

    /* initialize testStreamBuf */
    memset(testStreamBuf, '*', sizeof(testStreamBuf));
    testStreamBuf[sizeof(testStreamBuf)-1] = 0;
#endif

    outTestStream << "\x42\x65\x67\x69\x6E\x6E\x69\x6E\x67\x20\x6F\x66\x20\x74\x65\x73\x74\x20";
    outTestStream << str1 << "\x20\x20" << str2 << str3 << "\x31\x20" << UTF8_NEW_LINE << str4 << ends;
#ifdef USE_SSTREAM
    string tempStr = outTestStream.str();
    const char *testStreamBuf = tempStr.c_str();
#endif
    if (strcmp(testStreamBuf, testStr) != 0) {
        log_err("Got: \"%s\", Expected: \"%s\"\n", testStreamBuf, testStr);
    }

    inTestStream >> inStr >> inStr2;
    if (inStr.compare(thisMu) != 0) {
        u_austrncpy(inStrC, inStr.getBuffer(), inStr.length());
        inStrC[inStr.length()] = 0;
        log_err("Got: \"%s\", Expected: \"tHis\\u03BC\"\n", inStrC);
    }
    if (inStr2.compare(mu) != 0) {
        u_austrncpy(inStrC, inStr.getBuffer(), inStr.length());
        inStrC[inStr.length()] = 0;
        log_err("Got: \"%s\", Expected: \"mu\"\n", inStrC);
    }

    /* return the default converter to the original state. */
    ucnv_setDefaultName(defConvName);
    defConv = u_getDefaultConverter(&status);
    if (U_FAILURE(status)) {
        log_err("Can't get default converter");
        return;
    }
    ucnv_close(defConv);
#else
    log_info("U_IOSTREAM_SOURCE is disabled\n");
#endif
}
U_CDECL_END

U_CFUNC void addStreamTests(TestNode** root) {
    addTest(root, &TestStream, "stream/TestStream");
}

