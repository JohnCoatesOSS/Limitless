/********************************************************************
 * COPYRIGHT: 
 * Copyright (c) 1997-2006, International Business Machines Corporation and
 * others. All Rights Reserved.
 ********************************************************************/

/**
 * IntlTestFormat is the medium level test class for everything in the directory "format".
 */

#include "unicode/utypes.h"

#if !UCONFIG_NO_FORMATTING

#include "itformat.h"
#include "tsdate.h"
#include "tsnmfmt.h"
#include "caltest.h"
#include "callimts.h"
#include "tztest.h"
#include "tzbdtest.h"
#include "tsdcfmsy.h"       // DecimalFormatSymbols
#include "tchcfmt.h"
#include "tsdtfmsy.h"       // DateFormatSymbols
#include "dcfmapts.h"       // DecimalFormatAPI
#include "tfsmalls.h"       // Format Small Classes
#include "nmfmapts.h"       // NumberFormatAPI
#include "numfmtst.h"       // NumberFormatTest
#include "sdtfmtts.h"       // SimpleDateFormatAPI
#include "dtfmapts.h"       // DateFormatAPI
#include "dtfmttst.h"       // DateFormatTest
#include "tmsgfmt.h"        // TestMessageFormat
#include "dtfmrgts.h"       // DateFormatRegressionTest
#include "msfmrgts.h"       // MessageFormatRegressionTest
#include "miscdtfm.h"       // DateFormatMiscTests
#include "nmfmtrt.h"        // NumberFormatRoundTripTest
#include "numrgts.h"        // NumberFormatRegressionTest
#include "dtfmtrtts.h"      // DateFormatRoundTripTest
#include "pptest.h"         // ParsePositionTest
#include "calregts.h"       // CalendarRegressionTest
#include "tzregts.h"        // TimeZoneRegressionTest
#include "astrotst.h"       // AstroTest
#include "incaltst.h"       // IntlCalendarTest
#include "calcasts.h"       // CalendarCaseTest

#define TESTCLASS(id, TestClass)          \
    case id:                              \
        name = #TestClass;                \
        if (exec) {                       \
            logln(#TestClass " test---"); \
            logln((UnicodeString)"");     \
            TestClass test;               \
            callTest(test, par);          \
        }                                 \
        break

void IntlTestFormat::runIndexedTest( int32_t index, UBool exec, const char* &name, char* par )
{
    // for all format tests, always set default Locale and TimeZone to ENGLISH and PST.
    TimeZone* saveDefaultTimeZone = NULL;
    Locale  saveDefaultLocale = Locale::getDefault();
    if (exec) {
        saveDefaultTimeZone = TimeZone::createDefault();
        TimeZone *tz = TimeZone::createTimeZone("PST");
        TimeZone::setDefault(*tz);
        delete tz;
        UErrorCode status = U_ZERO_ERROR;
        Locale::setDefault( Locale::getEnglish(), status );
        if (U_FAILURE(status)) {
            errln("itformat: couldn't set default Locale to ENGLISH!");
        }
    }
    if (exec) logln("TestSuite Format: ");
    switch (index) {
        TESTCLASS(0,IntlTestDateFormat);
        TESTCLASS(1,IntlTestNumberFormat);
        TESTCLASS(2,CalendarTest);
        TESTCLASS(3,CalendarLimitTest);
        TESTCLASS(4,TimeZoneTest);
        TESTCLASS(5,TimeZoneBoundaryTest);
        TESTCLASS(6,TestChoiceFormat);
        TESTCLASS(7,IntlTestDecimalFormatSymbols);
        TESTCLASS(8,IntlTestDateFormatSymbols);
        TESTCLASS(9,IntlTestDecimalFormatAPI);
        TESTCLASS(10,TestFormatSmallClasses);
        TESTCLASS(11,IntlTestNumberFormatAPI);
        TESTCLASS(12,IntlTestSimpleDateFormatAPI);
        TESTCLASS(13,IntlTestDateFormatAPI);
        TESTCLASS(14,DateFormatTest);
        TESTCLASS(15,TestMessageFormat);
        TESTCLASS(16,NumberFormatTest);
        TESTCLASS(17,DateFormatRegressionTest);
        TESTCLASS(18,MessageFormatRegressionTest);
        TESTCLASS(19,DateFormatMiscTests);
        TESTCLASS(20,NumberFormatRoundTripTest);
        TESTCLASS(21,NumberFormatRegressionTest);
        TESTCLASS(22,DateFormatRoundTripTest);
        TESTCLASS(23,ParsePositionTest);
        TESTCLASS(24,CalendarRegressionTest);
        TESTCLASS(25,TimeZoneRegressionTest);
        TESTCLASS(26,IntlCalendarTest);
        TESTCLASS(27,AstroTest);
        TESTCLASS(28,CalendarCaseTest);

        default: name = ""; break; //needed to end loop
    }
    if (exec) {
        // restore saved Locale and TimeZone
        TimeZone::adoptDefault(saveDefaultTimeZone);
        UErrorCode status = U_ZERO_ERROR;
        Locale::setDefault( saveDefaultLocale, status );
        if (U_FAILURE(status)) {
            errln("itformat: couldn't re-set default Locale!");
        }
    }
}

#endif /* #if !UCONFIG_NO_FORMATTING */
