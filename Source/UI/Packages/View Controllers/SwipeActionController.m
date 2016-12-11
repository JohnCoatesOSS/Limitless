//
//  SwipeActionController.m
//  Limitless
//
//  Created by Thatchapon Unprasert on 12/11/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "SwipeActionController.h"

@implementation SwipeActionController

static bool DismissAfterProgress_;
static bool DismissAsQueue_;
static bool FromSwipeAction_;
static bool ClickDowngrade_;
static bool ClickBuy_;

+ (void) setDismissAfterProgress:(bool)dismiss
{
    DismissAfterProgress_ = dismiss;
}

+ (bool) shouldDismissAfterProgress
{
    return DismissAfterProgress_;
}

+ (void) setDismissAsQueue:(bool)dismiss
{
    DismissAsQueue_ = dismiss;
}

+ (bool) shouldDismissAsQueue
{
    return DismissAsQueue_;
}

+ (void) setFromSwipeAction:(bool)swipe
{
    FromSwipeAction_ = swipe;
}

+ (bool) fromSwipeAction
{
    return FromSwipeAction_;
}

+ (void) setAutoClickDowngrade:(bool)click
{
    ClickDowngrade_ = click;
}

+ (bool) shouldAutoClickDowngrade
{
    return ClickDowngrade_;
}

+ (void) setAutoClickBuy:(bool)click
{
    ClickBuy_ = click;
}

+ (bool)shouldAutoClickBuy
{
    return ClickBuy_;
}

@end
