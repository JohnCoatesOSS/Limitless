//
//  SystemHelpers.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import <IOKit/IOKitLib.h>
#import "SystemHelpers.h"
#import "iPhonePrivate.h"

CFStringRef (*$MGCopyAnswer)(CFStringRef);

NSObject *CYIOGetValue(const char *path, NSString *property) {
    io_registry_entry_t entry(IORegistryEntryFromPath(kIOMasterPortDefault, path));
    if (entry == MACH_PORT_NULL)
        return nil;
    
    CFTypeRef value(IORegistryEntryCreateCFProperty(entry, (CFStringRef) property, kCFAllocatorDefault, 0));
    IOObjectRelease(entry);
    
    if (value == NULL)
        return nil;
    return [(id) value autorelease];
}

NSString *CYHex(NSData *data, bool reverse) {
    if (data == nil)
        return nil;
    
    size_t length([data length]);
    uint8_t bytes[length];
    [data getBytes:bytes];
    
    char string[length * 2 + 1];
    for (size_t i(0); i != length; ++i)
        sprintf(string + i * 2, "%.2x", bytes[reverse ? length - i - 1 : i]);
    
    return [NSString stringWithUTF8String:string];
}

NSString *UniqueIdentifier(UIDevice *device) {
    if ([Device isSimulator]) {
        return [NSUUID UUID].UUIDString;
    }
    if (kCFCoreFoundationVersionNumber < 800) { // iOS 7.x
        return [device ?: [UIDevice currentDevice] uniqueIdentifier];
    }
    
    return [(id)$MGCopyAnswer(CFSTR("UniqueDeviceID")) autorelease];
}