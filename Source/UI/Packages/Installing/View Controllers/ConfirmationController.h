//
//  ConfirmationController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaWebViewController.h"
#import "Database.h"

@protocol ConfirmationControllerDelegate
- (void) cancelAndClear:(bool)clear;
- (void) confirmWithNavigationController:(UINavigationController *)navigation;
- (void) queue;
@end

@interface ConfirmationController : CydiaWebViewController {
    _transient Database *database_;
    
    _H<UIAlertView> essential_;
    
    _H<NSDictionary> changes_;
    @public _H<NSMutableArray> issues_;
    _H<NSDictionary> sizes_;
    
    BOOL substrate_;
}

- (id) initWithDatabase:(Database *)database;
- (void) _doContinue;
- (void) confirmButtonClicked;

@end
