//
//  main.m
//  Cydia
//
//  Created on 8/29/16.
//

#import <UIKit/UIKit.h>
#import "Application.h"
#import "AppDelegate.h"
#import "Startup.h"
#include <signal.h>
#include <csignal>

int main(int argc, char *argv[]) {
    if ([Platform shouldWaitForDebugger]) {
        raise(SIGSTOP);
    }

    @autoreleasepool {
        [Startup runStartupTasks];
        return UIApplicationMain(argc, argv,
                                 NSStringFromClass([Application class]),
                                 NSStringFromClass([Application class]));
    }
}
