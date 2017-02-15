//
//  CydiaTabBarController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CyteKit.h"
#import "Delegates.h"
#import "Database.h"
#import "CydiaObject.h"

@interface CydiaTabBarController : CyteTabBarController
<UITabBarControllerDelegate, FetchDelegate> {
    _transient Database *database_;
    
    _H<UIActivityIndicatorView> indicator_;
    
    bool updating_;
    // XXX: ok, "updatedelegate_"?...
    _transient NSObject<CydiaDelegate> *updatedelegate_;
}

- (id) initWithDatabase:(Database *)database;

- (void) beginUpdate;
- (BOOL) updating;
- (void) cancelUpdate;
- (void) setUpdateDelegate:(id)delegate;

@end
