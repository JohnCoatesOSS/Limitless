//
//  NSDOMNodeList+Hooks.mm
//  Cydia
//
//  Created on 8/31/16.
//
// Can't be implemented as a regular category because NSDOMNodeList
// is added as a class at runtime.

#import "NSDOMNodeList+Hooks.h"
#import <WebKit/DOMNodeList.h>
#import "System.h"

@interface NSDOMNodeList_Hooks ()

@end

@implementation NSDOMNodeList_Hooks

+ (void)setUpHooks {
    SEL selector = @selector(countByEnumeratingWithState:objects:count:);
    Method method = class_getInstanceMethod(self, selector);
    IMP implementation = method_getImplementation(method);
    const char *typeEncoding = method_getTypeEncoding(method);
    
    Class targetClass = objc_getClass("DOMNodeList");
    class_addMethod(targetClass, selector,
                    implementation, typeEncoding);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id _Nonnull [])objects
                                    count:(NSUInteger)count {
    size_t length = [self length] - state->state;
    if (length <= 0) {
        return 0;
    }
    if (length > count) {
        length = count;
    }
    for (size_t i(0); i != length; ++i) {
        objects[i] = [self item:(unsigned int)state->state++];
    }
    state->itemsPtr = objects;
    state->mutationsPtr = (unsigned long *)self;
    return length;
}

#pragma mark - Placeholders

- (unsigned)length {
    return 0;
}

- (DOMNode *)item:(unsigned)index {
    return nil;
}

@end
