//
//  LMXDevice.m
//  Limitless
//
//  Created by John Coates on 4/19/17.
//  Copyright © 2017 Limitless. All rights reserved.
//

#import "LMXDevice.h"
#import <dlfcn.h>
#import <sys/sysctl.h>

@interface UIDevice (Private)

- (NSString *)uniqueIdentifier;

@end

@implementation LMXDevice

+ (BOOL)isSimulator {
#if (TARGET_OS_SIMULATOR)
    return TRUE;
#else
    return FALSE;
#endif
}

+ (NSString *)uniqueIdentifier {
    static NSString *uniqueIdentifier = nil;
    if (uniqueIdentifier) {
        return uniqueIdentifier;
    }
    
    if ([self isSimulator]) {
        uniqueIdentifier = @"0100110001001101010100110110100101101101";
        return uniqueIdentifier;
    }
    if (kCFCoreFoundationVersionNumber < 800) { // iOS 7.x
        uniqueIdentifier = [[UIDevice currentDevice] uniqueIdentifier];
        return uniqueIdentifier;
    }
    
    void *lib = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
    CFStringRef (*MGCopyAnswer_ptr)(CFStringRef property) = dlsym(lib, "MGCopyAnswer");
    
    uniqueIdentifier = (__bridge_transfer NSString*)MGCopyAnswer_ptr(CFSTR("UniqueDeviceID"));
    if (!uniqueIdentifier) {
        uniqueIdentifier = @"unknown";
    }
    
    return uniqueIdentifier;
}

+ (NSString *)machineIdentifier {
    static NSString *machineIdentifier = nil;
    if (machineIdentifier) {
        return machineIdentifier;
    }
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == -1){
        perror("sysctlbyname(\"hw.machine\", ?)");
        machineIdentifier = @"unknown";
    } else {
        machineIdentifier = @(machine);
        free(machine);
    }
    
    return machineIdentifier;
}

@end
