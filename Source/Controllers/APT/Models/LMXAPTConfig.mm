//
//  LMXAPTConfig.m
//  Limitless
//
//  Created on 12/6/16.
//

#import "LMXAPTConfig.h"
#import "Apt.h"

@interface LMXAPTConfig ()

@end

@implementation LMXAPTConfig

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    string value = _config->Find(key.UTF8String);
    if (value.empty()) {
        return nil;
    }
    
    return @(value.c_str());
}

- (void)setObject:(NSString *)obj forKeyedSubscript:(NSString *)key {
    _config->Set(key.UTF8String, obj.UTF8String);
}

@end
