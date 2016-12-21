//
//  LMXSettingsSection.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "LMXSettingsSection.h"

@interface LMXSettingsSection ()

@end

@implementation LMXSettingsSection

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];

    if (self) {
        _title = title;
    }

    return self;
}

@end
