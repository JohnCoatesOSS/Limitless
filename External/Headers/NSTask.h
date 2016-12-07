#import <Foundation/NSObject.h>

typedef NS_ENUM(NSInteger, NSTaskTerminationReason) {
    NSTaskTerminationReasonExit = 1,
    NSTaskTerminationReasonUncaughtSignal = 2
};

NS_ASSUME_NONNULL_BEGIN

extern NSString const *NSTaskDidTerminateNotification;

@interface NSTask : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (nullable, copy) NSString *launchPath;
@property (nullable, copy) NSArray<NSString *> *arguments;
@property (nullable, copy) NSDictionary<NSString *, NSString *> *environment;
@property (copy) NSString *currentDirectoryPath;

@property (nullable, retain) id standardInput;
@property (nullable, retain) id standardOutput;
@property (nullable, retain) id standardError;

@property (readonly) int processIdentifier;
@property (readonly, getter=isRunning) BOOL running;
@property (readonly) int terminationStatus;
@property (readonly) NSTaskTerminationReason terminationReason;
@property (nullable, copy) void (^terminationHandler)(NSTask *);
@property NSQualityOfService qualityOfService;

- (void)launch;
- (void)interrupt;
- (void)terminate;
- (BOOL)suspend;
- (BOOL)resume;
- (void)waitUntilExit;

@end
NS_ASSUME_NONNULL_END
