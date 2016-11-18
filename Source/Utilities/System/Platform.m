//
//  Platform.m
//  Cydia
//
//  Created by John Coates on 11/17/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import "Platform.h"

@implementation Platform

+ (BOOL)isSandboxed {
    if ([Device isSimulator]) {
        return TRUE;
    }
    NSString *executablePath = [NSBundle mainBundle].executablePath;
    if ([executablePath hasPrefix:@"/Applications"] ||
        [executablePath hasPrefix:@"/var/mobile/Applications"]) {
        return FALSE;
    } else {
        return TRUE;
    }
}

@end
