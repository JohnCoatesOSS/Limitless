//
//  APTDownloadItem.h
//  Limitless
//
//  Created on 12/20/16.
//

typedef NS_ENUM(NSUInteger, APTDownloadState) {
    APTDownloadStateIdle,
    APTDownloadStateDownloading,
    APTDownloadStateDone,
    APTDownloadStateError,
    APTDownloadStateAuthenticationError,
    APTDownloadStateTransientNetworkError
};

@interface APTDownloadItem : NSObject

@property (readonly, nonatomic) BOOL finished;
@property (readonly, nonatomic) APTDownloadState state;
@property (readonly, nonatomic) NSURL *url;
@property (readonly, nonatomic) NSString *errorMessage;

@end
