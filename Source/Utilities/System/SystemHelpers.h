//
//  SystemHelpers.h
//  Cydia
//
//  Created on 8/29/16.
//

NSObject *CYIOGetValue(const char *path, NSString *property);

NSString *CYHex(NSData *data, bool reverse = false);


extern CFStringRef (*$MGCopyAnswer)(CFStringRef);

NSString *UniqueIdentifier(UIDevice *device = nil);