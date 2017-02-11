//
//  SwipeActionController.h
//  Limitless
//
//  Created by Thatchapon Unprasert on 12/11/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwipeActionController : NSObject
+ (instancetype) sharedInstance;
@property(assign) BOOL dismissAfterProgress;
@property(assign) BOOL dismissAsQueue;
@property(assign) BOOL fromSwipeAction;
@property(assign) BOOL autoClickDowngrade;
@property(assign) BOOL autoClickBuy;
- (BOOL) shortLabel;
- (BOOL) autoDismissWhenQueue;
- (BOOL) autoPerform;
- (NSString *) installString;
- (NSString *) reinstallString;
- (NSString *) upgradeString;
- (NSString *) removeString;
- (NSString *) queueString;
- (NSString *) clearString;
- (NSString *) downgradeString;
- (NSString *) buyString;
- (NSString *) normalizedString:(NSString *)string;
- (NSString *) queueString:(NSString *)action;
@end
