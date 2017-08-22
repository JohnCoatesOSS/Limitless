//
//  APTError.m
//  Limitless
//
//  Created on 12/18/16.
//

#import "APTError.h"

NSErrorDomain const APTErrorDomain = @"APTErrorDomain";
NSErrorDomain const APTWarningDomain = @"APTWarningDomain";

@implementation APTError

+ (instancetype)unknownErrorWithMessage:(NSString *)errorMessage {
    NSErrorDomain domain = APTErrorDomain;
    NSInteger code = APTErrorUnknown;
    NSDictionary *userInfo =  @{ NSLocalizedDescriptionKey: errorMessage };
    
    return [self errorWithDomain:domain code:code userInfo:userInfo];
}

@end
