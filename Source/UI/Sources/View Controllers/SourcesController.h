//
//  SourcesController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"

@class Database, UIProgressHUD;

@interface SourcesController : CyteViewController
<UITableViewDataSource, UITableViewDelegate> {
    _transient Database *database_;
    unsigned era_;
    
    _H<UITableView, 2> list_;
    _H<NSMutableArray> sources_;
    int offset_;
    
    _H<NSString> href_;
    _H<UIProgressHUD> hud_;
    _H<NSError> error_;
    
    NSURLConnection *trivial_bz2_;
    NSURLConnection *trivial_gz_;
    
    BOOL cydia_;
}

- (id) initWithDatabase:(Database *)database;
- (void) updateButtonsForEditingStatusAnimated:(BOOL)animated;

- (void) showAddSourcePrompt;

@end