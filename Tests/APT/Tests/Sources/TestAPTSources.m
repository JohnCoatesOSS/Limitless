//
//  TestAPTSources.m
//  Limitless
//
//  Created on 12/18/16.
//

#import <XCTest/XCTest.h>
#import "APTSourceList.h"
#import "APTManager.h"

@interface TestAPTSources : XCTestCase

@end

@implementation TestAPTSources

- (void)setUp {
    [super setUp];
    APTManager *manager = [APTManager sharedInstance];
    [manager setup];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testLoadSources {
    APTSourceList *list = [[APTSourceList alloc] initWithMainList];
    XCTestExpectation *loadExpectation = [self expectationWithDescription:@"Load Sources"];
    [list performUpdateInBackgroundWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
        XCTAssertTrue(success, "Sources loaded successfully");
        if (!success) {
            NSLog(@"Loading sources errors: %@", errors);
        }
        
        [loadExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError * _Nullable error) {
    }];
}

- (void)testVerifyExpectedSources {
    APTSourceList *list = [[APTSourceList alloc] initWithMainList];
    
    NSArray <APTSource *> *sources = list.sources;
    NSLog(@"sources: %@", sources);
}


@end
