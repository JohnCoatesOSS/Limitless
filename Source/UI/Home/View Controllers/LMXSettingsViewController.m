//
//  SettingsController.m
//  Limitless
//
//  Created on 12/5/16.
//

#import "LMXSettingsViewController.h"
#import "LMXSettingsTableViewCell.h"
#import "LMXSettingsSection.h"
#import "LMXSettingsItem.h"

static NSString * const kCellIdentifier = @"LMXSettingCell";

@interface LMXSettingsViewController ()

@property UITableView *tableView;
@property (nonatomic) NSArray<LMXSettingsSection *> *sections;

@end

@implementation LMXSettingsViewController

// MARK: - Init

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Settings";
    }
    
    return self;
}

// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialSetup];
}

- (void)loadView {
    [super loadView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

// MARK: - Setup

- (void)initialSetup {
    [self tableSetup];
}

- (void)tableSetup {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:LMXSettingsTableViewCell.class
           forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.tableView];
}

// MARK: - Table Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMXSettingsTableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                           forIndexPath:indexPath];
    
    LMXSettingsItem *item = self.sections[indexPath.section].items[indexPath.row];
    cell.item = item;
    
    return cell;
}

// MARK: - Table Delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

// MARK: - Navigation

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://settings"];
}

// MARK: - Sections

- (NSArray<LMXSettingsSection *> *)sections {
    if (_sections) {
        return _sections;
    }
    
    _sections = @[
                 [self theme],
                 [self refresh]
                 ];
    
    return _sections;
}

- (LMXSettingsSection *)theme {
    LMXSettingsSection *section = [[LMXSettingsSection alloc] initWithTitle:@"Theme"];
    
    section.items = @[
                      [[LMXSettingsItem alloc] initWithKey:@"enableDarkMode"
                                                      name:@"Dark Mode"
                                                      type:LMXSettingToggle],
                      [[LMXSettingsItem alloc] initWithKey:@"enableRotation"
                                                      name:@"Enable Rotation"
                                                      type:LMXSettingToggle]
                      ];
    
    return section;
}

- (LMXSettingsSection *)refresh {
    LMXSettingsSection *section = [[LMXSettingsSection alloc] initWithTitle:@"Refresh Settings"];
    
    LMXSettingsItem *timeoutInSeconds;
    timeoutInSeconds = [[LMXSettingsItem alloc] initWithKey:@"customTimeoutSeconds"
                                                       name:@"Time in Seconds"
                                                       type:LMXSettingUnsignedIntValue];
    timeoutInSeconds.defaultValue = @(25);
    
    section.items = @[
                      [[LMXSettingsItem alloc] initWithKey:@"enableDarkMode"
                                                      name:@"Auto Refresh at Launch"
                                                      type:LMXSettingToggle],
                      [[LMXSettingsItem alloc] initWithKey:@"enableCustomTimeout"
                                                      name:@"Custom Timeout"
                                                      type:LMXSettingToggle],
                      timeoutInSeconds
                      ];
    return section;
}

// MARK: - Keyboard Events

- (void)registerForKeyboardNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShow:)
                               name:UIKeyboardWillShowNotification object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHide:)
                               name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                               name:UIKeyboardWillShowNotification object:nil];
    
    [notificationCenter removeObserver:self
                               name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = keyboardBoundsValue.CGRectValue;
    // According to https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
    // we should only use FrameEnd's size information and ignore the origin
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGRect tableFrameInScreenCoordinates = [self.tableView convertRect:self.tableView.bounds toView:nil];
    CGFloat yInsetPadding = 10;
    CGFloat yInset = keyboardBounds.size.height + yInsetPadding;
    CGFloat tableFrameMaxY = CGRectGetMaxY(tableFrameInScreenCoordinates);
    CGFloat insetMinY = CGRectGetMaxY(screenBounds) - yInset;
    CGFloat tableInsetY = MAX(tableFrameMaxY - insetMinY, 0);
    
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = tableInsetY;
    self.tableView.contentInset = contentInset;
    UIEdgeInsets scrollInsets = self.tableView.scrollIndicatorInsets;
    scrollInsets.bottom = tableInsetY;
    self.tableView.scrollIndicatorInsets = scrollInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 0;
    self.tableView.contentInset = contentInset;
    UIEdgeInsets scrollInsets = self.tableView.scrollIndicatorInsets;
    scrollInsets.bottom = 0;
    self.tableView.scrollIndicatorInsets = scrollInsets;
}

@end
