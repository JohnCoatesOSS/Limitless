//
//  APTCacheFile+Legacy.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "APTCacheFile+Legacy.h"
#import "Package.h"

@implementation APTCacheFile (Legacy)

- (Package *)packageWithName:(nonnull NSString *)name
                    database:(nonnull Database *)database {
    @synchronized (self) {
        
        pkgCacheFile &cache = *self.cacheFile;
        if (static_cast<pkgDepCache *>(cache) == NULL)
            return nil;
        pkgCache::PkgIterator iterator = cache->FindPkg(name.UTF8String, "any");
        
        if (iterator.end()) {
            return nil;
        }
        
        return [Package packageWithIterator:iterator
                                   withZone:NULL
                                     inPool:NULL
                                   database:database];
    };
}

@end
