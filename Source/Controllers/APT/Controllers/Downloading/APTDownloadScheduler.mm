//
//  APTDownloadScheduler.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "Apt.h"
#import "APTDownloadScheduler-Private.h"

@interface APTDownloadScheduler ()

@property pkgAcquire *scheduler;

@end

@implementation APTDownloadScheduler

// MARK: - Init / Dealloc

- (instancetype)initWithStatusDelegate:(pkgAcquireStatus *)statusDelegate {
    self = [super init];

    if (self) {
        _scheduler = new pkgAcquire(statusDelegate);
    }

    return self;
}

- (void)dealloc {
    delete _scheduler;
}

// MARK: - Run

- (APTDownloadSchedulerRunResult)run {
    return [self runWithDelegateInterval:500000];
}

- (APTDownloadSchedulerRunResult)runWithDelegateInterval:(int)delegateInterval {
    pkgAcquire::RunResult result = self.scheduler->Run(delegateInterval);
    
    switch (result) {
        case pkgAcquire::RunResult::Continue:
            return APTDownloadSchedulerRunResultSuccess;
        case pkgAcquire::RunResult::Failed:
            return APTDownloadSchedulerRunResultFailed;
        case pkgAcquire::RunResult::Cancelled:
            return APTDownloadSchedulerRunResultCancelled;
    }
}

- (NSUInteger)bytesDownloading {
    return self.scheduler->FetchNeeded();
}

- (NSUInteger)bytesDownloaded {
    return self.scheduler->PartialPresent();
}

- (BOOL)eraseFilesNotInOperationInDirectory:(NSString *)directoryPath {
    std::string directory = std::string(directoryPath.UTF8String);
    return self.scheduler->Clean(directory);
}

- (void)terminate {
    self.scheduler->Shutdown();
}

@end
