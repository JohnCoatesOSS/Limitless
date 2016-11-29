//
//  CydiaScript.h
//  Cydia
//
//  Created on 8/30/16.
//

#import <WebKit/WebScriptObject.h>

@interface NSObject (CydiaScript)
- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context;
@end