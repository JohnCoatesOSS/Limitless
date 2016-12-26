//
//  LMXSettingsController.h
//  Limitless
//
//  Created by John Coates on 12/22/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

// MARK: - Notification Names

extern NSNotificationName const LMXNotificationSettingsChanged;

// MARK: - Settings Keys

extern NSString * const kSettingDarkModeEnabled;
extern NSString * const kSettingRotationEnabled;
extern NSString * const kSettingAutoRefreshOnLaunch;
extern NSString * const kSettingCustomRefreshTimeoutEnabled;
extern NSString * const kSettingRefreshTimeoutInSeconds;

@interface LMXSettingsController : NSObject

// MARK: - Convenience Properties

/// Exposes object for use with keyed subscripting.
@property (class, readonly) LMXSettingsController *keyed;

@property (class, getter=isDarkModeEnabled) BOOL darkModeEnabled;
@property (class, getter=isRotationEnabled) BOOL rotationEnabled;
@property (class) BOOL autoRefreshOnLaunch;
@property (class, getter=isCustomRefreshTimeoutEnabled) BOOL customRefreshTimeoutEnabled;
@property (class) NSTimeInterval refreshTimeout;

// MARK: - Convenience Methods

/// Returns current setting, returning default if no user defined setting.
+ (id)objectForKey:(NSString *)settingsKey;
/// Returns object only if user has defined option.
+ (id)userDefinedObjectForKey:(NSString *)settingsKey;
+ (id)defaultValueForKey:(NSString *)settingsKey;
+ (void)setValueForKey:(NSString *)settingsKey withObject:(id)object;

@end
