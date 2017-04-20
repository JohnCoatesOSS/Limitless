//
//  APTCacheFile+Legacy.h
//  Limitless
//
//  Created on 12/19/16.
//

#import "APTCacheFile-Private.h"

@class Package, Database;

NS_ASSUME_NONNULL_BEGIN

@interface APTCacheFile (Legacy)

- (nullable Package *)packageWithName:(NSString *)name
                    database:(Database *)database;

@end

NS_ASSUME_NONNULL_END
