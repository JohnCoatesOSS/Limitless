//
//  APTSourceList.h
//  Limitless
//
//  Created on 12/17/16.
//

@class APTSource, APTSourceList;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SourceUpdateStatusLoading,
    SourceUpdateStatusFinished,
    SourceUpdateStatusFailed
} SourceUpdateStatus;

typedef void (^SourcesUpdateStatusBlock)(NSURL *url, SourceUpdateStatus status);
typedef void (^SourcesUpdateCompletion)(BOOL success, NSArray<NSError *> *errors);

@interface APTSourceList : NSObject

@property (readonly, nonatomic) NSArray<APTSource *> *sources;

+ (instancetype)main;
- (instancetype)initWithMainList;
- (instancetype)initWithListFilePath:(NSString *)filePath;

- (void)performUpdateInBackgroundWithCompletion:(nullable SourcesUpdateCompletion)completion;
- (void)performUpdateInBackgroundWithCompletion:(nullable SourcesUpdateCompletion)completion
                                    statusBlock:(nullable SourcesUpdateStatusBlock)statusBlock;

@end

NS_ASSUME_NONNULL_END
