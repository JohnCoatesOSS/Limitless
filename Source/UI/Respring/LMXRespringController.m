//
//  LMXRespringController.m
//  Limitless
//
//  12/1/16.
//

#import "LMXRespringController.h"
#import "LMXRespringViewController.h"
#import "SpringBoardServices.h"
#import "FrontBoardServices.h"

#include <objc/objc.h>
#include <objc/runtime.h>

@implementation LMXRespringController

static UIWindow *_window = nil;

+ (void)startRespring {
    _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    _window.rootViewController = [LMXRespringViewController new];
    _window.alpha = 0;
    [_window makeKeyAndVisible];
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn;
    
    [UIView animateWithDuration:0.45
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:1
                        options:animationOptions
                     animations:^{
                         _window.alpha = 1;
                     }
                     completion:^(BOOL completed){
                         [self executeRespring];
                     }];
}

+ (void)executeRespring {
    if(objc_getClass("SBSRelaunchAction")) {
        [self executeRespringWithSnapshot];
    } else {
        float delayToReadLabel = 1.5;
        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW,
                                                     (int64_t)(delayToReadLabel * NSEC_PER_SEC));
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
            [self executeLegacyRespring];
        });
        
    }
}

+ (void)executeLegacyRespring {
    SBSRestartRenderServerAction *restartAction = [SBSRestartRenderServerAction
                                                   restartActionWithTargetRelaunchURL:nil];
    [self sendRestartAction:restartAction];
}

+ (void)executeRespringWithSnapshot {
    SBSRelaunchAction *restartAction = [SBSRelaunchAction
                                        actionWithReason:@"RestartRenderServer"
                                        options:SBSRelaunchOptionsSnapshot
                                        targetURL:nil];
    
    [self sendRestartAction:restartAction];
}


+ (void)sendRestartAction:(id)restartAction {
    NSSet *actions = [NSSet setWithObject:restartAction];
    FBSSystemService *frontBoardService = [FBSSystemService sharedService];
    [frontBoardService sendActions:actions withResult:nil];
}

@end
