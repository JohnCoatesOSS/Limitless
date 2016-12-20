//
//  APTPackageManager.h
//  Limitless
//
//  Created on 12/19/16.
//

typedef NS_ENUM(NSUInteger, APTInstallResult) {
    APTInstallResultCompleted,
    APTInstallResultFailed,
    APTInstallResultIncomplete,
};

@class APTCacheFile;

@interface APTPackageManager : NSObject

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile;

- (APTInstallResult)performInstallationWithOutputToFileDescriptor:(int)fileDescriptor;

@end
