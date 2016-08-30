//
//  HomeController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaWebViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface HomeController : CydiaWebViewController {
    CFRunLoopRef runloop_;
    SCNetworkReachabilityRef reachability_;
}

@end