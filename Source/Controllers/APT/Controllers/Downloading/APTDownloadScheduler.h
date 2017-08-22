//
//  APTDownloadScheduler.h
//  Limitless
//
//  Created on 12/19/16.
//

typedef NS_ENUM(NSUInteger, APTDownloadResult) {
    APTDownloadResultSuccess,
    APTDownloadResultFailed,
    APTDownloadResultCancelled,
};

@class APTDownloadItem;

@interface APTDownloadScheduler : NSObject

- (APTDownloadResult)run;

- (NSUInteger)bytesDownloading;
- (NSUInteger)bytesDownloaded;

@property (readonly, nonatomic) NSArray<APTDownloadItem *> *items;

@end
