//
//  LMXSettingTableViewCell.h
//  Limitless
//
//  Created on 12/20/16.
//

#import <UIKit/UIKit.h>

@class LMXSettingsItem;

@interface LMXSettingsTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, retain, strong) LMXSettingsItem *item;

@end
