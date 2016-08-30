//
//  CydiaTabBarController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Substrate.hpp"
#import "CydiaTabBarController.h"
#import "DisplayHelpers.hpp"
#import "UIGlobals.h"
#import "SourceStatus.hpp"


@implementation CydiaTabBarController

- (NSArray *) navigationURLCollection {
    NSMutableArray *items([NSMutableArray array]);
    
    // XXX: Should this deal with transient view controllers?
    for (id navigation in [self viewControllers]) {
        NSArray *stack = [navigation performSelector:@selector(navigationURLCollection)];
        if (stack != nil)
            [items addObject:stack];
    }
    
    return items;
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;
        [self setDelegate:self];
        
        indicator_ = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteTiny] autorelease];
        [indicator_ setOrigin:CGPointMake(kCFCoreFoundationVersionNumber >= 800 ? 2 : 4, 2)];
        
        [[self view] setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    } return self;
}

- (void) beginUpdate {
    if (updating_)
        return;
    
    UIViewController *controller([[self viewControllers] objectAtIndex:1]);
    UITabBarItem *item([controller tabBarItem]);
    
    [item setBadgeValue:@""];
    UIView *badge(MSHookIvar<UIView *>([item view], "_badge"));
    
    [indicator_ startAnimating];
    [badge addSubview:indicator_];
    
    [updatedelegate_ retainNetworkActivityIndicator];
    updating_ = true;
    
    [NSThread
     detachNewThreadSelector:@selector(performUpdate)
     toTarget:self
     withObject:nil
     ];
}

- (void) performUpdate {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    
    SourceStatus status(self, database_);
    [database_ updateWithStatus:status];
    
    [self
     performSelectorOnMainThread:@selector(completeUpdate)
     withObject:nil
     waitUntilDone:NO
     ];
    
    [pool release];
}

- (void) stopUpdateWithSelector:(SEL)selector {
    updating_ = false;
    [updatedelegate_ releaseNetworkActivityIndicator];
    
    UIViewController *controller([[self viewControllers] objectAtIndex:1]);
    [[controller tabBarItem] setBadgeValue:nil];
    
    [indicator_ removeFromSuperview];
    [indicator_ stopAnimating];
    
    [updatedelegate_ performSelector:selector withObject:nil afterDelay:0];
}

- (void) completeUpdate {
    if (!updating_)
        return;
    [self stopUpdateWithSelector:@selector(reloadData)];
}

- (void) cancelUpdate {
    [self stopUpdateWithSelector:@selector(updateDataAndLoad)];
}

- (void) cancelPressed {
    [self cancelUpdate];
}

- (BOOL) updating {
    return updating_;
}

- (bool) isSourceCancelled {
    return !updating_;
}

- (void) startSourceFetch:(NSString *)uri {
}

- (void) stopSourceFetch:(NSString *)uri {
}

- (void) setUpdateDelegate:(id)delegate {
    updatedelegate_ = delegate;
}

@end