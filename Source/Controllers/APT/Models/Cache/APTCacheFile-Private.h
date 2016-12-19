//
//  APTCacheFile-Private.h
//  Limitless
//
//  Created by John Coates on 12/18/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "Apt.h"
#import "APTCacheFile.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTCacheFile (Private)

@property (readonly) pkgCacheFile *cacheFile;

@end

APT_SILENCE_DEPRECATIONS_END
