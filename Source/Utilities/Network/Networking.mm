//
//  Networking.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "Networking.h"
#import <SystemConfiguration/SystemConfiguration.h>

_H<NSMutableDictionary> SessionData_;
_H<NSObject> HostConfig_;
_H<NSMutableSet> BridgedHosts_;
_H<NSMutableSet> InsecureHosts_;
_H<NSMutableSet> PipelinedHosts_;
_H<NSMutableSet> CachedURLs_;

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


NSString *VerifySource(NSString *href) {
    static RegEx href_r("(http(s?)://|file:///)[^# ]*");
    if (!href_r(href)) {
        [[[[UIAlertView alloc]
           initWithTitle:[NSString stringWithFormat:Colon_, Error_, UCLocalize("INVALID_URL")]
           message:UCLocalize("INVALID_URL_EX")
           delegate:nil
           cancelButtonTitle:UCLocalize("OK")
           otherButtonTitles:nil
           ] autorelease] show];
        
        return nil;
    }
    
    if (![href hasSuffix:@"/"])
        href = [href stringByAppendingString:@"/"];
    return href;
}