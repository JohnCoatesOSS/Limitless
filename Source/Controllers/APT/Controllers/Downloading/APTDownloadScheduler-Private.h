//
//  APTDownloadScheduler-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

#import "APTDownloadScheduler.h"

NS_ASSUME_NONNULL_BEGIN

@interface APTDownloadScheduler (Private)

@property (readonly) pkgAcquire *scheduler;

- (instancetype)initWithStatusDelegate:(pkgAcquireStatus *)statusDelegate;

- (APTDownloadResult)run;
- (APTDownloadResult)runWithDelegateInterval:(int)delegateInterval;

- (BOOL)eraseFilesNotInOperationInDirectory:(NSString *)directoryPath;

- (void)terminate;

@end

NS_ASSUME_NONNULL_END
