//
//  device.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "Device.h"

@interface Device ()

@end

@implementation Device

+ (BOOL)isPad {
    static BOOL isPadDevice = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(userInterfaceIdiom)]) {
            UIUserInterfaceIdiom idiom = device.userInterfaceIdiom;
            if (idiom == UIUserInterfaceIdiomPad) {
                isPadDevice = true;
            }
        }
    });
    
    return isPadDevice;
}

+ (BOOL)isSimulator {
#if (TARGET_OS_SIMULATOR)
    return TRUE;
#else
    return FALSE;
#endif
}

@end
