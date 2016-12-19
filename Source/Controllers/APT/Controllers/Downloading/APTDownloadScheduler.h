//
//  APTDownloadScheduler.h
//  Limitless
//
//  Created on 12/19/16.
//

typedef NS_ENUM(NSUInteger, APTDownloadSchedulerRunResult) {
    APTDownloadSchedulerRunResultSuccess,
    APTDownloadSchedulerRunResultFailed,
    APTDownloadSchedulerRunResultCancelled,
};

@interface APTDownloadScheduler : NSObject

- (APTDownloadSchedulerRunResult)run;

- (NSUInteger)bytesDownloading;
- (NSUInteger)bytesDownloaded;

@end
