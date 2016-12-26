//
//  SettingsSection.h
//  Limitless
//
//  Created on 12/20/16.
//

@class SettingsItem;

NS_ASSUME_NONNULL_BEGIN

@interface SettingsSection : NSObject

@property (nullable, readonly) NSString *title;
@property (strong, retain) NSArray <SettingsItem *> *items;

- (instancetype)initWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
