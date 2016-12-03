//
//  Platform.h
//  Cydia
//
//  11/17/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Platform : NSObject

+ (BOOL)isSandboxed;
+ (BOOL)shouldWaitForDebugger;
@end
