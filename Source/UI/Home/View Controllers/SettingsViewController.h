//
//  SettingsController.h
//  Limitless
//
//  Created by Shade Zepheri on 12/5/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *table;

@property (nonatomic) NSInteger *page;
@property (nonatomic, strong) UITableViewCell *defaultPageCell;

@property (nonatomic, strong) UISwitch *rotationSwitch;
@property (nonatomic, strong) UITableViewCell *rotationCell;

@property (nonatomic, strong) UISwitch *nightModeSwitch;
@property (nonatomic, strong) UITableViewCell *nightModeCell;

@property (nonatomic, strong) UISwitch *autoRefreshSwitch;
@property (nonatomic, strong) UITableViewCell *autoRefreshCell;

@property (nonatomic, strong) UISwitch *timeoutSwitch;
@property (nonatomic, strong) UITableViewCell *timeoutCell;

@property (nonatomic, strong) UITextField *customTimeout;
@property (nonatomic, strong) UITableViewCell *customTimeoutCell;

@end
