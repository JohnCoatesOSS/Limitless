//
//  SettingsController.m
//  Limitless
//
//  Created by John Coates on 12/22/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "SettingsController.h"

NSNotificationName const LMXNotificationSettingsChanged = @"LMXNotificationSettingsChanged";

// MARK: - Settings Keys With Their Default Values
NSString * const kSettingDarkModeEnabled = @"kSettingDarkModeEnabled";
NSString * const kSettingRotationEnabled = @"kSettingRotationEnabled";
NSString * const kSettingAutoRefreshOnLaunch = @"kSettingAutoRefreshOnLaunch";
NSString * const kSettingCustomRefreshTimeoutEnabled = @"kSettingCustomRefreshTimeoutEnabled";
NSString * const kSettingRefreshTimeoutInSeconds = @"kSettingRefreshTimeoutInSeconds";

@interface SettingsController ()

@property (class, readonly) NSUserDefaults *userDefaults;

@end

@implementation SettingsController

// MARK: - Internal

+ (NSUserDefaults *)userDefaults {
    static dispatch_once_t onceToken;
    static NSUserDefaults *userDefaults;
    dispatch_once(&onceToken, ^{
        userDefaults = NSUserDefaults.standardUserDefaults;
    });
    return userDefaults;
}

+ (instancetype)keyed {
    static dispatch_once_t onceToken;
    static SettingsController *keyed;
    dispatch_once(&onceToken, ^{
        keyed = [self new];
    });
    
    return keyed;
}

// MARK: - Default Values

+ (NSDictionary *)defaultValues {
    static dispatch_once_t onceToken;
    static NSDictionary *defaultValues;
    dispatch_once(&onceToken, ^{
        defaultValues = @{
                          kSettingDarkModeEnabled: @(FALSE),
                          kSettingRotationEnabled: @(TRUE),
                          kSettingAutoRefreshOnLaunch: @(TRUE),
                          kSettingCustomRefreshTimeoutEnabled: @(FALSE),
                          kSettingRefreshTimeoutInSeconds: @(25)
                          };
    });
    
    return defaultValues;
}

+ (id)defaultValueForKey:(NSString *)settingsKey {
    return self.defaultValues[settingsKey];
}

// MARK: - Current Values

+ (id)objectForKey:(NSString *)settingsKey {
    id savedValue = self.keyed[settingsKey];
    
    if (savedValue) {
        return savedValue;
    }
    
    id defaultValue = self.defaultValues[settingsKey];
    return defaultValue;
}

+ (id)userDefinedObjectForKey:(NSString *)settingsKey {
    return self.keyed[settingsKey];
}

+ (BOOL)boolValueForKey:(NSString *)settingsKey {
    NSNumber *defaultValue = self.defaultValues[settingsKey];
    
    NSNumber *savedValue = [self.userDefaults objectForKey:settingsKey];
    if (!savedValue || ![savedValue isKindOfClass:NSNumber.class]) {
        if (!defaultValue) {
            [NSException raise:@"Missing Default for Setting" format:@"No default value for %@", settingsKey];
        }
        
        return defaultValue.boolValue;
    }
    
    return savedValue.boolValue;
}

+ (NSTimeInterval)timeIntervalForKey:(NSString *)settingsKey {
    NSNumber *defaultValue = self.defaultValues[settingsKey];
    
    NSNumber *savedValue = [self.userDefaults objectForKey:settingsKey];
    if (!savedValue || ![savedValue isKindOfClass:NSNumber.class]) {
        if (!defaultValue) {
            [NSException raise:@"Missing Default for Setting" format:@"No default value for %@", settingsKey];
        }
        
        return defaultValue.doubleValue;
    }
    
    return savedValue.doubleValue;
}

// MARK: - Getting, Setting Values

+ (void)setValueForKey:(NSString *)settingsKey withObject:(id)object {
    [self.userDefaults setObject:object forKey:settingsKey];
    [self postSettingsUpdatedNotification:settingsKey];
}

+ (void)postSettingsUpdatedNotification:(NSString *)settingsKey {
    [NSNotificationCenter.defaultCenter postNotificationName:LMXNotificationSettingsChanged
                                                        object:settingsKey];
}

// MARK: - Keyed Subscripting Setting, Getting

- (id)objectForKeyedSubscript:(NSString *)settingsKey {
    return [self.class.userDefaults objectForKey:settingsKey];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)settingsKey {
    [self.class setValueForKey:settingsKey withObject:object];
}

// MARK: - Convenience Properties

+ (BOOL)isDarkModeEnabled {
    return [self boolValueForKey:kSettingDarkModeEnabled];
}

+ (void)setDarkModeEnabled:(BOOL)newValue {
    self.keyed[kSettingDarkModeEnabled] = @(newValue);
}

+ (BOOL)isRotationEnabled {
    return [self boolValueForKey:kSettingRotationEnabled];
}

+ (void)setRotationEnabled:(BOOL)newValue {
    self.keyed[kSettingRotationEnabled] = @(newValue);
}

+ (BOOL)autoRefreshOnLaunch {
    return [self boolValueForKey:kSettingAutoRefreshOnLaunch];
}

+ (void)setAutoRefreshOnLaunch:(BOOL)newValue {
    self.keyed[kSettingAutoRefreshOnLaunch] = @(newValue);
}

+ (BOOL)isCustomRefreshTimeoutEnabled {
    return [self boolValueForKey:kSettingCustomRefreshTimeoutEnabled];
}

+ (void)setCustomRefreshTimeoutEnabled:(BOOL)newValue {
    self.keyed[kSettingCustomRefreshTimeoutEnabled] = @(newValue);
}

+ (NSTimeInterval)refreshTimeout {
    return [self timeIntervalForKey:kSettingRefreshTimeoutInSeconds];
}

+ (void)setRefreshTimeout:(NSTimeInterval)newValue {
    self.keyed[kSettingRefreshTimeoutInSeconds] = @(newValue);
}

@end
