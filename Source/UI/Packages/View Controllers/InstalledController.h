//
//  InstalledController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "FilteredPackageListController.h"

@class Database;

@interface InstalledController : FilteredPackageListController {
    bool sectioned_;
}
@property (class, readwrite) BOOL isFiltered;

- (id)initWithDatabase:(Database *)database;
- (void)queueStatusDidChange;

@end
