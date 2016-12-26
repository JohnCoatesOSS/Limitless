//
//  SettingTableViewCell.h
//  Limitless
//
//  Created on 12/20/16.
//

#import <UIKit/UIKit.h>

@class SettingsItem;

@interface SettingsTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, retain, strong) SettingsItem *item;

@end
