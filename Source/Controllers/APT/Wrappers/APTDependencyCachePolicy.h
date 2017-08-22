//
//  APTDependencyCachePolicy.h
//  Limitless
//
//  Created on 12/7/16.
//

#import "Apt.h"

typedef NS_ENUM(NSUInteger, APTDependencyCachePolicyMode) {
    APTDependencyCachePolicyModeDelete = 0,
    APTDependencyCachePolicyModeKeep = 1,
    APTDependencyCachePolicyModeInstall = 2,
};

@interface APTDependencyCachePolicy : NSObject

- (BOOL)packageDependsOnMobileSubstrate:(pkgCache::PkgIterator)packageIterator;

- (pkgCache::VerIterator)versionIteratorForPackage:(pkgCache::PkgIterator)packageIterator;

@end
