//
//  APTErrorController.m
//  Limitless
//
//  Created on 12/18/16.
//

#import "APTErrorController.h"
#import "Apt.h"
#import "APTError.h"

@interface APTErrorController ()

@end

@implementation APTErrorController

/// Pops latest error if there is one.
+ (NSError *)popError {
    if (_error->empty()) {
        return nil;
    }
    
    std::string errorMessage;
    bool isError = _error->PopMessage(errorMessage);
    bool isWarning = !isError;
    
    NSErrorDomain domain = APTErrorDomain;
    NSInteger code = APTErrorUnknown;
    if (isWarning) {
        domain = APTWarningDomain;
        code = APTErrorWarning;
    }
    NSDictionary *userInfo =  @{
                                NSLocalizedDescriptionKey: @(errorMessage.c_str())
                                };
    NSLog(@"Popped error: %@", @(errorMessage.c_str()));
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSArray<APTError *> *)popErrors {
    NSMutableArray *errors = [NSMutableArray new];
    
    NSError *error = [self popError];
    while (error != nil) {
        [errors addObject:error];
        error = [self popError];
    }
    
    return errors;
}

/// Whether errors are pending.
+ (BOOL)errorsExist {
    bool isEmpty = _error->empty();
    return !isEmpty;
}

@end
