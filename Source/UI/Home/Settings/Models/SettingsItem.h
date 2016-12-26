//
//  SettingsItem.h
//  Limitless
//
//  Created on 12/20/16.
//
    
typedef NS_ENUM(NSUInteger, Setting) {
    SettingToggle,
    SettingUnsignedIntValue
};

@interface SettingsItem : NSObject

@property (readonly) NSString *key;
@property (readonly) NSString *name;
@property (readonly) Setting type;

@property (readonly, nonatomic) id defaultValue;
@property (readonly, nonatomic) id currentValue;

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
                       type:(Setting)type;

@end
