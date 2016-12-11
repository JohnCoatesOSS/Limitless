//
//  SwipeActionController.h
//  Limitless
//
//  Created by Thatchapon Unprasert on 12/11/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwipeActionController : NSObject
+ (void) setDismissAfterProgress:(bool)dismiss;
+ (bool) shouldDismissAfterProgress;
+ (void) setDismissAsQueue:(bool)dismiss;
+ (bool) shouldDismissAsQueue;
+ (void) setFromSwipeAction:(bool)swipe;
+ (bool) fromSwipeAction;
+ (void) setAutoClickDowngrade:(bool)click;
+ (bool) shouldAutoClickDowngrade;
+ (void) setAutoClickBuy:(bool)click;
+ (bool) shouldAutoClickBuy;
@end
