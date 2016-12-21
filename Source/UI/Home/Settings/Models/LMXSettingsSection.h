//
//  LMXSettingsSection.h
//  Limitless
//
//  Created on 12/20/16.
//

@class LMXSettingsItem;

NS_ASSUME_NONNULL_BEGIN

@interface LMXSettingsSection : NSObject

@property (nullable, readonly) NSString *title;
@property (strong, retain) NSArray <LMXSettingsItem *> *items;

- (instancetype)initWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
