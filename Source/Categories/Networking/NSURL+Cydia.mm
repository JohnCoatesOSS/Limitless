//
//  NSURL+Cydia.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "NSURL+Cydia.h"
#import "Networking.h"

@implementation NSURL (CydiaSecure)

- (bool) isCydiaSecure {
    if ([[[self scheme] lowercaseString] isEqualToString:@"https"])
        return true;
    
    @synchronized (HostConfig_) {
        if ([InsecureHosts_ containsObject:[self host]])
            return true;
    }
    
    return false;
}

@end