//
//  UIWebDocumentView+BugFixes.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import <UIKit/UIKit.h>
#import "iPhonePrivate.h"

// Apple Bug Fixes

@implementation UIWebDocumentView (Cydia)

- (void) _setScrollerOffset:(CGPoint)offset {
    UIScroller *scroller([self _scroller]);
    
    CGSize size([scroller contentSize]);
    CGSize bounds([scroller bounds].size);
    
    CGPoint max;
    max.x = size.width - bounds.width;
    max.y = size.height - bounds.height;
    
    // wtf Apple?!
    if (max.x < 0)
        max.x = 0;
    if (max.y < 0)
        max.y = 0;
    
    offset.x = offset.x < 0 ? 0 : offset.x > max.x ? max.x : offset.x;
    offset.y = offset.y < 0 ? 0 : offset.y > max.y ? max.y : offset.y;
    
    [scroller setOffset:offset];
}

@end