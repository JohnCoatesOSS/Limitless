//
//  Platform.m
//  Cydia
//
//  11/17/16.
//

#import "Platform.h"

@implementation Platform

+ (BOOL)publicReleaseBuild {
    #ifdef RELEASE_BUILD
    return TRUE;
    #endif
    return FALSE;
}

+ (BOOL)isSandboxed {
    if ([self publicReleaseBuild]) {
        return FALSE;
    }
    
    if ([Device isSimulator]) {
        return TRUE;
    }
    NSString *executablePath = [NSBundle mainBundle].executablePath;
    if ([executablePath hasPrefix:@"/Applications"] ||
        [executablePath hasPrefix:@"/var/mobile/Applications"] ||
        [executablePath hasPrefix:@"/private/var/mobile/Applications"]) {
        return FALSE;
    } else {
        return TRUE;
    }
}

+ (BOOL)shouldWaitForDebugger {
    #ifdef WAIT_FOR_DEBUGGER
    return TRUE;
    #endif
    
    return FALSE;
}

@end
