//
//  UINavigationController+Cydia.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "UINavigationController+Cydia.h"
#import "CyteKit.h"
#import "DisplayHelpers.hpp"

@implementation UINavigationController (Cydia)

- (NSArray *) navigationURLCollection {
    NSMutableArray *stack([NSMutableArray array]);
    
    for (CyteViewController *controller in [self viewControllers]) {
        NSString *url = [[controller navigationURL] absoluteString];
        if (url != nil)
            [stack addObject:url];
    }
    
    return stack;
}

- (void) reloadData {
    [super reloadData];
    
    UIViewController *visible([self visibleViewController]);
    if (visible != nil)
        [visible reloadData];
    
    // on the iPad, this view controller is ALSO visible. :(
    if (IsWildcat_)
        if (UIViewController *modal = [self modalViewController])
            if ([modal modalPresentationStyle] == UIModalPresentationFormSheet)
                if (UIViewController *top = [self topViewController])
                    if (top != visible)
                        [top reloadData];
}

- (void) unloadData {
    for (CyteViewController *page in [self viewControllers])
        [page unloadData];
    
    [super unloadData];
}

@end