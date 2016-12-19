//
//  APTCacheFile.h
//  Limitless
//
//  Created on 12/18/16.
//

NS_ASSUME_NONNULL_BEGIN

@interface APTCacheFile : NSObject <NSFastEnumeration>

- (nullable instancetype)initWithError:(NSError **)error;

@property (nonatomic, readonly) unsigned long pendingDeletions;
@property (nonatomic, readonly) unsigned long pendingInstalls;
@property (nonatomic, readonly) unsigned long brokenPackages;
@end

NS_ASSUME_NONNULL_END
