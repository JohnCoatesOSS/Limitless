//
//  LMXSettingsItem.h
//  Limitless
//
//  Created on 12/20/16.
//
    
typedef NS_ENUM(NSUInteger, LMXSetting) {
    LMXSettingToggle,
    LMXSettingUnsignedIntValue
};

@interface LMXSettingsItem : NSObject

@property (readonly) NSString *key;
@property (readonly) NSString *name;
@property (readonly) LMXSetting type;

@property (readonly, nonatomic) id defaultValue;
@property (readonly, nonatomic) id currentValue;

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
                       type:(LMXSetting)type;

@end
