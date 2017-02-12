//
//  NSError+Limitless.m
//  Limitless
//
//  Created on 12/5/16.
//

#import "NSError+Limitless.h"

static NSErrorDomain const LMXErrorDomain = @"Limitless";
static NSInteger LMXGenericErrorCode = 100;

@implementation NSError (Limitless)

+ (instancetype)limitlessErrorWithMessage:(NSString *)message {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: message
    };
    return [self errorWithDomain:LMXErrorDomain
                            code:LMXGenericErrorCode
                        userInfo:userInfo];
}

@end
