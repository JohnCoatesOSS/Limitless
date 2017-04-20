//
//  APTError.h
//  Limitless
//
//  Created on 12/18/16.
//

extern NSErrorDomain const APTErrorDomain;
extern NSErrorDomain const APTWarningDomain;

NS_ENUM(NSInteger) {
    APTErrorUnknown = 0,
    APTErrorWarning = 1
};

@interface APTError : NSError

+ (instancetype)unknownErrorWithMessage:(NSString *)errorMessage;
    
@end
