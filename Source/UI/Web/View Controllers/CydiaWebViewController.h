//
//  CydiaWebViewController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CydiaObject.h"
#import "Diversion.h"

@interface CydiaWebViewController : CyteWebViewController {
    _H<CydiaObject> cydia_;
}

+ (void) addDiversion:(Diversion *)diversion;
+ (NSURLRequest *) requestWithHeaders:(NSURLRequest *)request;
+ (void) didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame withCydia:(CydiaObject *)cydia;
- (void) setDelegate:(id)delegate;

@end
