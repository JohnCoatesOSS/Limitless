//
//  APTDownloadScheduler-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTDownloadScheduler.h"

NS_ASSUME_NONNULL_BEGIN

@interface APTDownloadScheduler (Private)

@property (readonly) pkgAcquire *scheduler;

- (instancetype)initWithStatusDelegate:(pkgAcquireStatus *)statusDelegate;

- (APTDownloadSchedulerRunResult)run;
- (APTDownloadSchedulerRunResult)runWithDelegateInterval:(int)delegateInterval;

- (BOOL)eraseFilesNotInOperationInDirectory:(NSString *)directoryPath;

- (void)terminate;

@end

NS_ASSUME_NONNULL_END
