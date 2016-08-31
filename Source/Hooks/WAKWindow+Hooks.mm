//
//  WAKWindow+Hooks.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "WAKWindow+Hooks.h"
#import "System.h"

static CGSize $WAKWindow$screenSize(WAKWindow *self, SEL _cmd) {
    return [UIScreen mainScreen].bounds.size;
    
}

@implementation WAKWindow (Hooks)

+ (void)setUpHooks {
    Class $WAKWindow;
    $WAKWindow = objc_getClass("WAKWindow");
    if ($WAKWindow != NULL)
        if (Method method = class_getInstanceMethod($WAKWindow, @selector(screenSize)))
            method_setImplementation(method, (IMP) &$WAKWindow$screenSize);
}

@end
