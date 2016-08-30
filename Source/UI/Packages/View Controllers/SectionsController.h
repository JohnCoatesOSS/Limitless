//
//  SectionsController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"

@class Database, Source;

@interface SectionsController : CyteViewController <
UITableViewDataSource,
UITableViewDelegate
> {
    _transient Database *database_;
    _H<NSString> key_;
    _H<NSMutableArray> sections_;
    _H<NSMutableArray> filtered_;
    _H<UITableView, 2> list_;
}

- (id) initWithDatabase:(Database *)database source:(Source *)source;
- (void) editButtonClicked;

@end