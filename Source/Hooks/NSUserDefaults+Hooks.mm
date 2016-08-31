//
//  NSUserDefaults+Hooks.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "NSUserDefaults+Hooks.h"
#import "System.h"
#import "iPhonePrivate.h"
#import "Substrate.hpp"
#import "Startup.h"
#import "SystemGlobals.h"
#import "CyteKit.h"
#import "GeneralGlobals.h"
#import "Networking.h"
#import "Package.h"
#import "DisplayHelpers.hpp"
#import "Defines.h"

Class $NSUserDefaults;

MSHook(id, NSUserDefaults$objectForKey$, NSUserDefaults *self, SEL _cmd, NSString *key) {
    if ([key respondsToSelector:@selector(isEqualToString:)] && [key isEqualToString:@"WebKitLocalStorageDatabasePathPreferenceKey"])
        return Cache("LocalStorage");
    return _NSUserDefaults$objectForKey$(self, _cmd, key);
}


@implementation NSUserDefaults (CydiaHooks)

+ (void)setUpHooks {
    $NSUserDefaults = objc_getClass("NSUserDefaults");
    Method NSUserDefaults$objectForKey$(class_getInstanceMethod($NSUserDefaults, @selector(objectForKey:)));
    if (NSUserDefaults$objectForKey$ != NULL) {
        _NSUserDefaults$objectForKey$ = reinterpret_cast<id (*)(NSUserDefaults *, SEL, NSString *)>(method_getImplementation(NSUserDefaults$objectForKey$));
        method_setImplementation(NSUserDefaults$objectForKey$, reinterpret_cast<IMP>(&$NSUserDefaults$objectForKey$));
    }
}

@end
