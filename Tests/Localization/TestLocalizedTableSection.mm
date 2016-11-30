//
//  TestLocalizedTableSection
//  Limitless
//
//

#import <XCTest/XCTest.h>
#import "Menes/Menes.h"
#import "Standard.h"
#import "CYString.hpp"
#import "UIGlobals.h"
#import "LMXLocalizedTableSections.h"

@interface LMXLocalizedTableSections ()

@property (class, readwrite) UTransliterator *transliterator;

@end

@interface TestLocalizedTableSection : XCTestCase

@property CYPool *pool;
@end

@implementation TestLocalizedTableSection

- (void)setUp {
    [super setUp];
    
    LMXLocalizedTableSections.testModeEnabled = TRUE;
    self.pool = new CYPool();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testLatinToGreekICU {
    NSString *icuIdentifier = @"Latin-Greek";
    unichar *uid = (unichar *)[icuIdentifier cStringUsingEncoding:NSUnicodeStringEncoding];
    
    UErrorCode resultCode = U_ZERO_ERROR;
    LMXLocalizedTableSections.transliterator = utrans_openU(uid, -1,
                                                             UTRANS_FORWARD, NULL,
                                                             0, NULL, &resultCode);
    
    if (!U_SUCCESS(resultCode)) {
        XCTFail("Couldn't create transliterator, error: %s", u_errorName(resultCode));
    }
    NSString *input = @"hello";
    NSString *expectedOuput = @"ἑλλο";
    
    CYString cyInput;
    cyInput.set(self.pool, input.UTF8String);
    
    CYString cyOuput;
    BOOL result = [LMXLocalizedTableSections transliterate:cyInput pool:self.pool output:&cyOuput];
    XCTAssertTrue(result, "ICU transliterate returned true");
    
    NSString *output = (NSString *)(CFStringRef) cyOuput;
    XCTAssertEqualObjects(output, expectedOuput, "Output matches");
    
    utrans_close(LMXLocalizedTableSections.transliterator);
    LMXLocalizedTableSections.transliterator = nil;
}

@end
