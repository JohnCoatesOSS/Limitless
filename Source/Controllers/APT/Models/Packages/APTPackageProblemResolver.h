//
//  APTPackageProblemResolver.h
//  Limitless
//
//  Created on 12/19/16.
//

@class APTCacheFile, APTPackage;

@interface APTPackageProblemResolver : NSObject

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile;

- (void)installProtectedPackages;
- (BOOL)resolveAndFixBroken:(BOOL)fixBroken;

- (void)clearPackage:(APTPackage *)package;
- (void)protectPackage:(APTPackage *)package;
- (void)removePackage:(APTPackage *)package;

@end
