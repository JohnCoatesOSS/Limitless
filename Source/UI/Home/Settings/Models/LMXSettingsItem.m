//
//  LMXSettingsItem.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "LMXSettingsItem.h"

@interface LMXSettingsItem ()

@end

@implementation LMXSettingsItem

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
                       type:(LMXSetting)type {
    self = [super init];

    if (self) {
        _key = key;
        _name = name;
        _type = type;
    }

    return self;
}

- (void)updateToReflectNewProperties {
    
}

@end
