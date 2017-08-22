//
//  APTErrorController.h
//  Limitless
//
//  Created on 12/18/16.
//

@class APTError;

@interface APTErrorController : NSObject

/// Pops latest error if there is one.
+ (nullable NSError *)popError;
+ (nonnull NSArray<NSError *> *)popErrors;

/// Whether errors are pending.
+ (BOOL)errorsExist;

@end
