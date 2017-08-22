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

@class APTCacheFile, APTSourceList, APTRecords, APTDownloadScheduler;

@interface APTPackageManager : NSObject

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile;

- (APTInstallResult)performInstallationWithOutputToFileDescriptor:(int)fileDescriptor;

- (BOOL)queueArchivesForDownloadWithScheduler:(APTDownloadScheduler *)downloadScheduler
                                   sourceList:(APTSourceList *)sourceList
                               packageRecords:(APTRecords *)records;

@end
