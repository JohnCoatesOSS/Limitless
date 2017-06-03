//
//  APTPackageManager.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "Apt.h"
#import "APTCacheFile-Private.h"
#import "APTDownloadScheduler-Private.h"
#import "APTRecords-Private.h"
#import "APTSourceList-Private.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTPackageManager ()

@property pkgPackageManager *packageManager;

@end

@implementation APTPackageManager

// MARK: - Initialize

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile {
    self = [super init];

    if (self) {
        pkgCacheFile &cache = *cacheFile.cacheFile;
        if (static_cast<pkgDepCache *>(cache) == NULL) {
            NSLog(@"Error: pkgCacheFile is not castable to pkgDepCache");
            return nil;
        }
        _packageManager = _system->CreatePM(cache);
    }

    return self;
}

// MARK: - Private Methods

- (BOOL)queueArchivesForDownloadWithScheduler:(APTDownloadScheduler *)downloadScheduler
                                   sourceList:(APTSourceList *)sourceList
                               packageRecords:(APTRecords *)records {
    return _packageManager->GetArchives(downloadScheduler.scheduler,
                                        sourceList.list, records.records);
    
}

- (APTInstallResult)performInstallationWithOutputToFileDescriptor:(int)fileDescriptor {
    
    pkgPackageManager::OrderResult result = _packageManager->DoInstall(fileDescriptor);
    
    switch (result) {
        case pkgPackageManager::OrderResult::Completed:
            return APTInstallResultCompleted;
        case pkgPackageManager::OrderResult::Failed:
            return APTInstallResultFailed;
        case pkgPackageManager::OrderResult::Incomplete:
            return APTInstallResultIncomplete;
    }
}

@end

APT_SILENCE_DEPRECATIONS_END
