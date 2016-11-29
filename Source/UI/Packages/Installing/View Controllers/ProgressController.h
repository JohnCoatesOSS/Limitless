//
//  ProgressController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CydiaWebViewController.h"
#import "Database.h"
#import "CydiaProgressData.h"

@interface ProgressController : CydiaWebViewController <ProgressDelegate> {
    _transient Database *database_;
    _H<CydiaProgressData, 1> progress_;
    unsigned cancel_;
}

- (id) initWithDatabase:(Database *)database delegate:(id)delegate;

- (void) invoke:(NSInvocation *)invocation withTitle:(NSString *)title;

- (void) setTitle:(NSString *)title;
- (void) setCancellable:(bool)cancellable;

@end
