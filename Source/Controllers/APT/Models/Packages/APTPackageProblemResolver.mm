//
//  APTPackageProblemResolver.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "APTPackageProblemResolver.h"
#import "Apt.h"
#import "APTCacheFile-Private.h"
#import "APTPackage-Private.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTPackageProblemResolver ()

@property pkgProblemResolver *problemResolver;

@end

@implementation APTPackageProblemResolver

// MARK: - Init & Dealloc

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile {
    self = [super init];

    if (self) {
        pkgCacheFile &cache = *cacheFile.cacheFile;
        self.problemResolver = new pkgProblemResolver(cache);
    }

    return self;
}

- (void)dealloc {
    delete _problemResolver;
}

// MARK: - Resolving

- (void)installProtectedPackages {
    self.problemResolver->InstallProtect();
}

- (BOOL)resolveAndFixBroken:(BOOL)fixBroken {
    bool fixBrokenCBool = fixBroken;
    return self.problemResolver->Resolve(fixBrokenCBool);
}

- (void)clearPackage:(APTPackage *)package {
    self.problemResolver->Clear(package.packageIterator);
}

- (void)protectPackage:(APTPackage *)package {
    self.problemResolver->Protect(package.packageIterator);
}

- (void)removePackage:(APTPackage *)package {
    self.problemResolver->Remove(package.packageIterator);
}

@end

APT_SILENCE_DEPRECATIONS_END
