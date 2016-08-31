//
//  main.m
//  Cydia
//
//  Created on 8/29/16.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Startup.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        [Startup runStartupTasks];
        return UIApplicationMain(argc, argv,
                                 nil, NSStringFromClass([AppDelegate class]));
    }
}