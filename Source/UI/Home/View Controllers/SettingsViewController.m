//
//  SettingsController.m
//  Limitless
//
//  Created on 12/5/16.
//

#import "SettingsViewController.h"
#import "SettingsTableViewCell.h"
#import "SettingsSection.h"
#import "SettingsItem.h"

static NSString * const kCellIdentifier = @"SettingCell";

@interface SettingsViewController ()

@property UITableView *tableView;
@property (nonatomic) NSArray<SettingsSection *> *sections;

@end

@implementation SettingsViewController

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
    [self.tableView registerClass:SettingsTableViewCell.class
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
    SettingsTableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                           forIndexPath:indexPath];
    
    SettingsItem *item = self.sections[indexPath.section].items[indexPath.row];
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

- (NSArray<SettingsSection *> *)sections {
    if (_sections) {
        return _sections;
    }
    
    _sections = @[
                 [self theme],
                 [self refresh]
                 ];
    
    return _sections;
}

- (SettingsSection *)theme {
    SettingsSection *section = [[SettingsSection alloc] initWithTitle:@"Theme"];
    
    section.items = @[
                      [[SettingsItem alloc] initWithKey:kSettingDarkModeEnabled
                                                      name:@"Dark Mode"
                                                      type:SettingToggle],
                      [[SettingsItem alloc] initWithKey:kSettingRotationEnabled
                                                      name:@"Enable Rotation"
                                                      type:SettingToggle]
                      ];
    
    return section;
}

- (SettingsSection *)refresh {
    SettingsSection *section = [[SettingsSection alloc] initWithTitle:@"Refresh Settings"];
    
    section.items = @[
                      [[SettingsItem alloc] initWithKey:kSettingAutoRefreshOnLaunch
                                                      name:@"Auto Refresh on Launch"
                                                      type:SettingToggle],
                      [[SettingsItem alloc] initWithKey:kSettingCustomRefreshTimeoutEnabled
                                                      name:@"Custom Timeout"
                                                      type:SettingToggle],
                      [[SettingsItem alloc] initWithKey:kSettingRefreshTimeoutInSeconds
                                                      name:@"Time in Seconds"
                                                      type:SettingUnsignedIntValue]
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
