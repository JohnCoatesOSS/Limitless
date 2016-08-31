//
//  Display.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Display : NSObject

// Scale
+ (CGFloat)screenScale;
+ (double)pointRoundedAtScreenScale:(double)point;
+ (CGRect)rectRoundedAtScreenScale:(CGRect)rect;

@end
