//
//  APTCacheFile-Private.h
//  Limitless
//
//  Created on 12/18/16.
//  
//

#import "Apt.h"
#import "APTCacheFile.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTCacheFile (Private)

@property (readonly) pkgCacheFile *cacheFile;

@end

APT_SILENCE_DEPRECATIONS_END
