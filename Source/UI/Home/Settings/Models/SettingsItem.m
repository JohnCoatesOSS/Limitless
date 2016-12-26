//
//  SettingsItem.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "SettingsItem.h"

@interface SettingsItem ()

@property (readwrite, nonatomic, strong) id defaultValue;
@property (readwrite, nonatomic, strong) id currentValue;

@end

@implementation SettingsItem

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
                       type:(Setting)type {
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
    _defaultValue = [SettingsController defaultValueForKey:self.key];
    
    return _defaultValue;
}

- (id)currentValue {
    return [SettingsController objectForKey:self.key];
}

@end
