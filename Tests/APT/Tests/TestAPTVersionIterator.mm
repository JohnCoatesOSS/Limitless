//
//  TestAPTVersionIterator.m
//  Limitless
//
//  Created on 12/17/16.
//

#import <XCTest/XCTest.h>
#import "Apt.h"

@interface TestAPTVersionIterator : XCTestCase

@end

@implementation TestAPTVersionIterator

- (void)setUp {
    APTManager *manager = [APTManager sharedInstance];
    [manager setup];
    APTManager.debugMode = FALSE;
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPackageEnumeration {
    pkgCacheFile rawCacheFile;
    OpProgress progress;
    bool opened = rawCacheFile.Open(progress, false);
    XCTAssertTrue(opened, "Opened cache file");
    if (!opened) {
        return;
    }
    
    int packageCount = 0;
    pkgCache::PkgIterator iterator;
    iterator = iterator = rawCacheFile->PkgBegin();
    while(!iterator.end()) {
        packageCount += 1;
        iterator++;
    }
    
    pkgCache owner = *rawCacheFile;
    long expectedPackages = owner.HeaderP->PackageCount;
    
    NSError *error = nil;
    APTCacheFile *cacheFile = [[APTCacheFile alloc] initWithError:&error];
    XCTAssertNotNil(cacheFile, "APTCacheFile initialized successfully");
    XCTAssertNil(error, "APTCacheFile didn't return any errors");
    
    if (error) {
        NSLog(@"error initing cache file: %@", error);
        return;
    }
    
    int enumeratedPackages = 0;
    for (NSString *packageName in cacheFile) {
        XCTAssertNotNil(packageName, "Valid package.");
        enumeratedPackages += 1;
    }
    
    XCTAssertEqual(packageCount, enumeratedPackages,
                   "NSFastEnumeration enumerated through all packages");
    XCTAssertEqual(enumeratedPackages, expectedPackages,
                   "Expected packages has correct value");
}

@end
