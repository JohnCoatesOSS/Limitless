//
//  CydiaScript.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaScript.h"

@implementation NSObject (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    return self;
}

@end

@implementation NSArray (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    WebScriptObject *object([context evaluateWebScript:@"[]"]);
    for (size_t i(0), e([self count]); i != e; ++i)
        [object setWebScriptValueAtIndex:i value:[[self objectAtIndex:i] Cydia$webScriptObjectInContext:context]];
    return object;
}

@end

@implementation NSDictionary (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    WebScriptObject *object([context evaluateWebScript:@"({})"]);
    for (id i in self)
        [object setValue:[[self objectForKey:i] Cydia$webScriptObjectInContext:context] forKey:i];
    return object;
}

@end