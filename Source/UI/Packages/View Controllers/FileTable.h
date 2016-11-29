//
//  FileTable.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Database.h"
#import "Package.h"

@interface FileTable : CyteViewController <
UITableViewDataSource,
UITableViewDelegate
> {
    _transient Database *database_;
    _H<Package> package_;
    _H<NSString> name_;
    _H<NSMutableArray> files_;
    _H<UITableView, 2> list_;
}

- (id) initWithDatabase:(Database *)database;
- (void) setPackage:(Package *)package;

@end