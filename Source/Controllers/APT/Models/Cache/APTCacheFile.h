//
//  APTCacheFile.h
//  Limitless
//
//  Created on 12/18/16.
//

@class Package, Database;

NS_ASSUME_NONNULL_BEGIN

@interface APTCacheFile : NSObject <NSFastEnumeration>

- (nullable instancetype)initWithError:(NSError **)error;

- (Package *)packageWithName:(NSString *)name
                    database:( Database *)database;

@property (nonatomic, readonly) unsigned long pendingDeletions;
@property (nonatomic, readonly) unsigned long pendingInstalls;
@property (nonatomic, readonly) unsigned long brokenPackages;
@end

NS_ASSUME_NONNULL_END
