//
//  PackageSettingsController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"

@class Database, Package;
@interface PackageSettingsController : CyteViewController
<UITableViewDataSource, UITableViewDelegate> {
    _transient Database *database_;
    _H<NSString> name_;
    _H<Package> package_;
    _H<UITableView, 2> table_;
    _H<UISwitch> subscribedSwitch_;
    _H<UISwitch> ignoredSwitch_;
    _H<UITableViewCell> subscribedCell_;
    _H<UITableViewCell> ignoredCell_;
}

- (id) initWithDatabase:(Database *)database package:(NSString *)package;

@end