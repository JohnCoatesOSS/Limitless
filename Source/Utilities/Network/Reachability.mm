//
//  Reachability.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>

bool IsReachable(const char *name) {
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef reachability;
    reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
                                                       name);
    SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    
    // XXX: this elaborate mess is what Apple is using to determine this? :(
    // XXX: do we care if the user has to intervene? maybe that's ok?
    bool isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    bool connectionRequired = flags & kSCNetworkReachabilityFlagsConnectionRequired;
    bool connectionOnDemand = flags & kSCNetworkReachabilityFlagsConnectionOnDemand;
    bool connectionOnTraffic = flags & kSCNetworkReachabilityFlagsConnectionOnTraffic;
    bool interventionRequired = flags & kSCNetworkReachabilityFlagsInterventionRequired;
    bool isWWAN = flags & kSCNetworkReachabilityFlagsIsWWAN;
    bool connectionAvailable = !connectionRequired || connectionOnDemand || connectionOnTraffic;
    
    return isReachable && connectionAvailable && (!interventionRequired || isWWAN);
}
