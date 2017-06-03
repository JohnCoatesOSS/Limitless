//
//  main.m
//  Cydia
//
//  Created on 8/29/16.
//

#import <UIKit/UIKit.h>
#import "Application.h"
#import "Startup.h"
#import <signal.h>
#import <csignal>
#import "APTManager.h"

int main(int argc, char *argv[]) {
    if ([Platform shouldWaitForDebugger]) {
        raise(SIGSTOP);
    }
    
    if ([APTManager debugMode]) {
        [APTManager clearAPTState];
    }

    @autoreleasepool {
        [Startup runStartupTasks];
        return UIApplicationMain(argc, argv,
                                 NSStringFromClass([Application class]),
                                 NSStringFromClass([Application class]));
    }
}
