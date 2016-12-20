//
//  APTDownloadScheduler.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "Apt.h"
#import "APTDownloadScheduler-Private.h"
#import "APTDownloadItem-Private.h"

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

- (APTDownloadResult)run {
    return [self runWithDelegateInterval:500000];
}

- (APTDownloadResult)runWithDelegateInterval:(int)delegateInterval {
    pkgAcquire::RunResult result = self.scheduler->Run(delegateInterval);
    
    switch (result) {
        case pkgAcquire::RunResult::Continue:
            return APTDownloadResultSuccess;
        case pkgAcquire::RunResult::Failed:
            return APTDownloadResultFailed;
        case pkgAcquire::RunResult::Cancelled:
            return APTDownloadResultCancelled;
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

// MARK: - Items

- (NSArray<APTDownloadItem *> *)items {
    NSMutableArray *items = [NSMutableArray new];
    pkgAcquire *scheduler = self.scheduler;
    pkgAcquire::ItemIterator itemIterator = scheduler->ItemsBegin();
    while (itemIterator != scheduler->ItemsEnd()) {
        pkgAcquire::Item *rawItem = *itemIterator;
        APTDownloadItem *item = [[APTDownloadItem alloc] initWithItem:rawItem];
        [items addObject:item];
        itemIterator++;
    }
    return items;
}

@end
