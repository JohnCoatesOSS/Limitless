//
//  SettingsController.h
//  Limitless
//
//  Created on 12/5/16.
//

#import <UIKit/UIKit.h>

@interface LMXSettingsViewController : UIViewController
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
