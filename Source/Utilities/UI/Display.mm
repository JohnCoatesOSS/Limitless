//
//  Display.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "Display.h"

@interface Display ()

@end

@implementation Display

#pragma mark - Scale

+ (CGFloat)screenScale {
    static dispatch_once_t onceToken;
    static CGFloat screenScale;
    dispatch_once(&onceToken, ^{
        UIScreen *screen = [UIScreen mainScreen];
        if ([screen respondsToSelector:@selector(scale)]) {
            screenScale = screen.scale;
        } else {
            screenScale = 1;
        }
    });
    return screenScale;
}

+ (double)pointRoundedAtScreenScale:(double)point {
    double screenScale = [self screenScale];
    point *= screenScale;
    point = round(point);
    point /= screenScale;
    return point;
    
}

+ (CGRect)rectRoundedAtScreenScale:(CGRect)rect {
    CGFloat screenScale = [self screenScale];
    rect.origin.x *= screenScale;
    rect.origin.y *= screenScale;
    rect.size.width *= screenScale;
    rect.size.height *= screenScale;
    rect = CGRectIntegral(rect);
    rect.origin.x /= screenScale;
    rect.origin.y /= screenScale;
    rect.size.width /= screenScale;
    rect.size.height /= screenScale;
    return rect;
}


@end
