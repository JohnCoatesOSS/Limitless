//
//  LMXLaunchProcess.h
//  Limitless
//
//  Created by John Coates on 11/30/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMXLaunchProcess : NSObject

/// Synchronous launch, use instead of system()
+ (NSString *)launchProcessAtPath:(NSString *)path;

/// Synchronous launch, use instead of system()
+ (NSString *)launchProcessAtPath:(NSString *)path
                       outputPath:(NSString *)outputPath
                    withArguments:(NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION;

/// Synchronous launch, use instead of system()
+ (NSString *)launchProcessAtPath:(NSString *)path
                    withArguments:(NSString *)firstArgument, ... NS_REQUIRES_NIL_TERMINATION;

@end
