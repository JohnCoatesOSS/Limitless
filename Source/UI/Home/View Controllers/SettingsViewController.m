//
//  SettingsController.m
//  Limitless
//
//  Created by Shade Zepheri on 12/5/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "SettingsViewController.h"

@implementation SettingsViewController

// MARK: - View Lifecycle

- (void)loadView {
    [super loadView];
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self setView:view];
    
    _table = [[UITableView alloc] initWithFrame:[[self view] bounds] style:UITableViewStyleGrouped];
    [_table setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [(UITableView *) _table setDataSource:self];
    [_table setDelegate:self];
    [view addSubview:_table];
    
    _defaultPageCell = [[UITableViewCell alloc] init];
    [[_defaultPageCell textLabel] setText:@"Default Page"];
    [_defaultPageCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    _defaultPageCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    _rotationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    [_rotationSwitch setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    _rotationSwitch.onTintColor = [UIColor purpleColor];
    [_rotationSwitch addTarget:self action:@selector(enableRotation:) forControlEvents:UIControlEventValueChanged];
    
    _rotationCell = [[UITableViewCell alloc] init];
    [[_rotationCell textLabel] setText:@"Enable Rotation"];
    [_rotationCell setAccessoryView:_rotationSwitch];
    [_rotationCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    _nightModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    [_nightModeSwitch setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    _nightModeSwitch.onTintColor = [UIColor purpleColor];
    [_nightModeSwitch addTarget:self action:@selector(setNightMode:) forControlEvents:UIControlEventValueChanged];
    
    _nightModeCell = [[UITableViewCell alloc] init];
    [[_nightModeCell textLabel] setText:@"Dark Mode"];
    _nightModeCell.accessoryView = _nightModeSwitch;
    [_nightModeCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    _autoRefreshSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    [_autoRefreshSwitch setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    _autoRefreshSwitch.onTintColor = [UIColor purpleColor];
    [_autoRefreshSwitch addTarget:self action:@selector(enableAutoRefresh:) forControlEvents:UIControlEventValueChanged];
    
    _autoRefreshCell = [[UITableViewCell alloc] init];
    [[_autoRefreshCell textLabel] setText:@"Auto Refresh at Launch"];
    [_autoRefreshCell setAccessoryView:_autoRefreshSwitch];
    [_autoRefreshCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    _timeoutSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    [_timeoutSwitch setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    _timeoutSwitch.onTintColor = [UIColor purpleColor];
    [_timeoutSwitch addTarget:self action:@selector(enableCustomTimeout:) forControlEvents:UIControlEventValueChanged];
    
    _timeoutCell = [[UITableViewCell alloc] init];
    [[_timeoutCell textLabel] setText:@"Custom Timeout"];
    [_timeoutCell setAccessoryView:_timeoutSwitch];
    [_timeoutCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    _customTimeout = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    _customTimeout.keyboardType = UIKeyboardTypeNumberPad;
    _customTimeout.textAlignment = NSTextAlignmentLeft;
    _customTimeout.returnKeyType = UIReturnKeyDone;
    _customTimeout.placeholder = @"25";
    [_customTimeout addTarget:self action:@selector(setCustomTimeout:) forControlEvents:UIControlEventEditingDidEnd];
    
    _customTimeoutCell = [[UITableViewCell alloc] init];
    [[_customTimeoutCell textLabel] setText:@"Time in Seconds:"];
    [_customTimeoutCell setAccessoryView:_customTimeout];
    [_customTimeoutCell setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setTitle:@"Settings"];
    [_rotationSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"rotationEnabled"]];
    [_nightModeSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"nightModeEnabled"]];
    [_autoRefreshSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"autoRefreshEnabled"]];
    [_timeoutSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"customTimeoutEnabled"]];
}

// MARK: - Table Data Source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return 1;
        case 2:
            return 2;
    };
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Refresh Settings";
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: return _defaultPageCell;
                case 1: return _rotationCell;
                case 2: return _nightModeCell;
            }
        case 1:
            switch (indexPath.row) {
                case 0: return _autoRefreshCell;
            }
        case 2:
            switch (indexPath.row) {
                case 0: return _timeoutCell;
                case 1: return _customTimeoutCell;
            }
    }
    return nil;
}

// MARK: - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSLog(@"Default Page was clicked");
    }
}



// MARK: - Navigation

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://settings"];
}

// MARK: - Settings Events

- (void)setNightMode:(id)control {
    BOOL value = [control isOn];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"nightModeEnabled"];
    NSLog(value ? @"Yes" : @"No");
}

- (void)enableRotation:(id)control {
    BOOL value = [control isOn];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"rotationEnabled"];
    NSLog(value ? @"Yes" : @"No");
}

- (void)enableAutoRefresh:(id)control {
    BOOL value = [control isOn];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"autoRefreshEnabled"];
    NSLog(value ? @"Yes" : @"No");
}

- (void)enableCustomTimeout:(id)control {
    BOOL value = [control isOn];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"customTimeoutEnabled"];
    NSLog(value ? @"Yes" : @"No");
}

- (void)setCustomTimeout:(UITextField *)customTimeout {
    CGFloat timeout = [customTimeout.text floatValue];
    [[NSUserDefaults standardUserDefaults] setFloat:timeout forKey:@"customTimeout"];
    NSLog(@"%f", timeout);
}

@end
