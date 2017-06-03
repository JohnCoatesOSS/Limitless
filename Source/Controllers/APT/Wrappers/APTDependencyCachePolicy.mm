//
//  APTDependencyCachePolicy.m
//  Limitless
//
//  Created on 12/7/16.
//

#import "APTDependencyCachePolicy.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTDependencyCachePolicy ()

@property pkgDepCache::Policy *policy;

@end

@implementation APTDependencyCachePolicy

- (instancetype)init {
    self = [super init];

    if (self) {
        _policy = new pkgDepCache::Policy();
    }

    return self;
}

- (void)dealloc {
    delete _policy;
}

- (BOOL)packageDependsOnMobileSubstrate:(pkgCache::PkgIterator)packageIterator {
    pkgCache::VerIterator versionIterator = self.policy->GetCandidateVer(packageIterator);
    
    if (versionIterator.end()) {
        return FALSE;
    }
    
    pkgCache::DepIterator dependencyIterator = versionIterator.DependsList();
    
    for (; dependencyIterator.end() == false; dependencyIterator++) {
        unsigned char type = dependencyIterator->Type;
        BOOL isDependency = type == pkgCache::Dep::Depends;
        BOOL isPreDepedency = type == pkgCache::Dep::PreDepends;
        if (!isDependency && !isPreDepedency) {
            continue;
        }
        
        pkgCache::PkgIterator package = dependencyIterator.TargetPkg();
        if (package.end()) {
            continue;
        }
        
        NSString *packageName = @(package.Name());
        if ([packageName isEqualToString:@"mobilesubstrate"]) {
            NSLog(@"found mobilesubstrate depedency");
            return TRUE;
        }
    }
    
    return FALSE;
}

- (pkgCache::VerIterator)versionIteratorForPackage:(pkgCache::PkgIterator)packageIterator {
    return self.policy->GetCandidateVer(packageIterator);
}

@end

APT_SILENCE_DEPRECATIONS_END
