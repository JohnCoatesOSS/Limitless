//
//  HomeController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "HomeController.h"
#import "UIGlobals.h"
#import "DisplayHelpers.hpp"
#import "LMXSettingsViewController.h"

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

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)settingsButtonClicked {
    LMXSettingsViewController *controller = [[[LMXSettingsViewController alloc] init] autorelease];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    controller.navigationItem.rightBarButtonItem = doneButton;
    [navigationController.navigationItem setTitle:@"Settings"];
    [self presentViewController:navigationController animated:YES completion:nil];
}


- (UIBarButtonItem *) leftButton {
    return [[[UIBarButtonItem alloc]
             initWithTitle:UCLocalize("SETTINGS")
             style:UIBarButtonItemStylePlain
             target:self
             action:@selector(settingsButtonClicked)
             ] autorelease];
}

@end
