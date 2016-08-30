//
//  HomeController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "HomeController.h"
#import "UIGlobals.h"
#import "DisplayHelpers.hpp"

@implementation HomeController

static void HomeControllerReachabilityCallback(SCNetworkReachabilityRef reachability, SCNetworkReachabilityFlags flags, void *info) {
    [(HomeController *) info dispatchEvent:@"CydiaReachabilityCallback"];
}

- (id) init {
    if ((self = [super init]) != nil) {
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/home/", UI_]]];
        [self reloadData];
        
        reachability_ = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "cydia.saurik.com");
        if (reachability_ != NULL) {
            SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
            SCNetworkReachabilitySetCallback(reachability_, HomeControllerReachabilityCallback, &context);
            
            CFRunLoopRef runloop(CFRunLoopGetCurrent());
            if (SCNetworkReachabilityScheduleWithRunLoop(reachability_, runloop, kCFRunLoopDefaultMode))
                runloop_ = runloop;
        }
    } return self;
}

- (void) dealloc {
    if (reachability_ != NULL && runloop_ != NULL)
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability_, runloop_, kCFRunLoopDefaultMode);
    [super dealloc];
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://home"];
}

- (void) aboutButtonClicked {
    UIAlertView *alert([[[UIAlertView alloc] init] autorelease]);
    
    [alert setTitle:UCLocalize("ABOUT_CYDIA")];
    [alert addButtonWithTitle:UCLocalize("CLOSE")];
    [alert setCancelButtonIndex:0];
    
    [alert setMessage:
     @"Copyright \u00a9 2008-2015\n"
     "SaurikIT, LLC\n"
     "\n"
     "Jay Freeman (saurik)\n"
     "saurik@saurik.com\n"
     "http://www.saurik.com/"
     ];
    
    [alert show];
}

- (UIBarButtonItem *) leftButton {
    return [[[UIBarButtonItem alloc]
             initWithTitle:UCLocalize("ABOUT")
             style:UIBarButtonItemStylePlain
             target:self
             action:@selector(aboutButtonClicked)
             ] autorelease];
}

@end