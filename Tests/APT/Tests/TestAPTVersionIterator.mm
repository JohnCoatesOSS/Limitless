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
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIterate {
    //pkgCache::PkgIterator iterator([package iterator]);
    //pkgCache::VerIterator ver(cache[iterator].InstVerIter(cache));
    // for (pkgCache::PkgIterator iterator = cache_->PkgBegin(); !iterator.end(); ++iterator)
    
    pkgCacheFile cacheFile;
    OpProgress progress;
    bool opened = cacheFile.Open(progress, false);
    NSLog(@"opened: %d", opened);
    XCTAssertTrue(opened, "Couldn't open cache file!");
    if (!opened) {   
        return;
    }
    
    //cacheFile->
    
    pkgSourceList *list = new pkgSourceList();
    list->ReadMainList();
    for (pkgSourceList::const_iterator source = list->begin(); source != list->end(); ++source) {
        NSLog(@"source!");
    }
    int packages = 0;
    for (pkgCache::PkgIterator iterator = cacheFile->PkgBegin(); !iterator.end(); ++iterator) {
        packages += 1;
//        NSLog(@"package!");
    }
    
    NSLog(@"packages: %d", packages);

}

@end
