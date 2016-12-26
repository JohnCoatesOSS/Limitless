//
//  SettingsSection.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "SettingsSection.h"

@interface SettingsSection ()

@end

@implementation SettingsSection

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];

    if (self) {
        _title = title;
    }

    return self;
}

@end
