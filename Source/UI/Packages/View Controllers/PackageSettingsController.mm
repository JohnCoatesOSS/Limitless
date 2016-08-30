//
//  PackageSettingsController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "PackageSettingsController.h"
#import "Database.h"
#import "Package.h"
#import "DisplayHelpers.hpp"

@implementation PackageSettingsController

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@/settings", (id) name_]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (package_ == nil)
        return 0;
    
    if ([package_ installed] == nil)
        return 1;
    else
        return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (package_ == nil)
        return 0;
    
    // both sections contain just one item right now.
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0)
        return UCLocalize("SHOW_ALL_CHANGES_EX");
    else
        return UCLocalize("IGNORE_UPGRADES_EX");
}

- (void) onSubscribed:(id)control {
    bool value([control isOn]);
    if (package_ == nil)
        return;
    if ([package_ setSubscribed:value])
        [delegate_ updateData];
}

- (void) _updateIgnored {
    const char *package([name_ UTF8String]);
    bool on([ignoredSwitch_ isOn]);
    
    FILE *dpkg(popen("/usr/libexec/cydia/cydo --set-selections", "w"));
    fwrite(package, strlen(package), 1, dpkg);
    
    if (on)
        fwrite(" hold\n", 6, 1, dpkg);
    else
        fwrite(" install\n", 9, 1, dpkg);
    
    pclose(dpkg);
}

- (void) onIgnored:(id)control {
    NSInvocation *invocation([NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_updateIgnored)]]);
    [invocation setTarget:self];
    [invocation setSelector:@selector(_updateIgnored)];
    
    [delegate_ reloadDataWithInvocation:invocation];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (package_ == nil)
        return nil;
    
    switch ([indexPath section]) {
        case 0: return subscribedCell_;
        case 1: return ignoredCell_;
            
            _nodefault
    }
    
    return nil;
}

- (void) loadView {
    UIView *view([[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]);
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self setView:view];
    
    table_ = [[[UITableView alloc] initWithFrame:[[self view] bounds] style:UITableViewStyleGrouped] autorelease];
    [table_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [(UITableView *) table_ setDataSource:self];
    [table_ setDelegate:self];
    [view addSubview:table_];
    
    subscribedSwitch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)] autorelease];
    [subscribedSwitch_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [subscribedSwitch_ addTarget:self action:@selector(onSubscribed:) forEvents:UIControlEventValueChanged];
    
    ignoredSwitch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)] autorelease];
    [ignoredSwitch_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [ignoredSwitch_ addTarget:self action:@selector(onIgnored:) forEvents:UIControlEventValueChanged];
    
    subscribedCell_ = [[[UITableViewCell alloc] init] autorelease];
    [subscribedCell_ setText:UCLocalize("SHOW_ALL_CHANGES")];
    [subscribedCell_ setAccessoryView:subscribedSwitch_];
    [subscribedCell_ setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    ignoredCell_ = [[[UITableViewCell alloc] init] autorelease];
    [ignoredCell_ setText:UCLocalize("IGNORE_UPGRADES")];
    [ignoredCell_ setAccessoryView:ignoredSwitch_];
    [ignoredCell_ setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem] setTitle:UCLocalize("SETTINGS")];
}

- (void) releaseSubviews {
    ignoredCell_ = nil;
    subscribedCell_ = nil;
    table_ = nil;
    ignoredSwitch_ = nil;
    subscribedSwitch_ = nil;
    
    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database package:(NSString *)package {
    if ((self = [super init]) != nil) {
        database_ = database;
        name_ = package;
    } return self;
}

- (void) reloadData {
    [super reloadData];
    
    package_ = [database_ packageWithName:name_];
    
    if (package_ != nil) {
        [subscribedSwitch_ setOn:([package_ subscribed] ? 1 : 0) animated:NO];
        [ignoredSwitch_ setOn:([package_ ignored] ? 1 : 0) animated:NO];
    } // XXX: what now, G?
    
    [table_ reloadData];
}

@end
