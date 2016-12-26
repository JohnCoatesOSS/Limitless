//
//  LMXSettingsItem.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "LMXSettingsItem.h"

@interface LMXSettingsItem ()

@property (readwrite, nonatomic, strong) id defaultValue;
@property (readwrite, nonatomic, strong) id currentValue;

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

- (id)defaultValue {
    if (_defaultValue) {
        return _defaultValue;
    }
    _defaultValue = [LMXSettingsController defaultValueForKey:self.key];
    
    return _defaultValue;
}

- (id)currentValue {
    return [LMXSettingsController objectForKey:self.key];
}

@end
