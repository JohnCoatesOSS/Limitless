//
//  NSURLConnection+Hooks.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "NSURLConnection+Hooks.h"
#import "System.h"
#import "iPhonePrivate.h"
#import "Substrate.hpp"
#import "Startup.h"
#import "SystemGlobals.h"
#import "CyteKit.h"
#import "GeneralGlobals.h"
#import "Networking.h"
#import "Package.h"
#import "DisplayHelpers.hpp"
#import "Defines.h"
#import "Flags.h"

Class $NSURLConnection;

MSHook(id, NSURLConnection$init$, NSURLConnection *self, SEL _cmd, NSURLRequest *request, id delegate, BOOL usesCache, int64_t maxContentLength, BOOL startImmediately, NSDictionary *connectionProperties) {
    NSMutableURLRequest *copy([[request mutableCopy] autorelease]);
    
    NSURL *url([copy URL]);
    
    NSString *host([url host]);
    NSString *scheme([[url scheme] lowercaseString]);
    
    NSString *compound([NSString stringWithFormat:@"%@:%@", scheme, host]);
    
    @synchronized (HostConfig_) {
        if ([copy respondsToSelector:@selector(setHTTPShouldUsePipelining:)])
            if ([PipelinedHosts_ containsObject:host] || [PipelinedHosts_ containsObject:compound])
                [copy setHTTPShouldUsePipelining:YES];
        
        if (NSString *control = [copy valueForHTTPHeaderField:@"Cache-Control"])
            if ([control isEqualToString:@"max-age=0"])
                if ([CachedURLs_ containsObject:url]) {
#if !ForRelease
                    NSLog(@"~~~: %@", url);
#endif
                    
                    [copy setCachePolicy:NSURLRequestReturnCacheDataDontLoad];
                    
                    [copy setValue:nil forHTTPHeaderField:@"Cache-Control"];
                    [copy setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
                    [copy setValue:nil forHTTPHeaderField:@"If-None-Match"];
                }
    }
    
    if ((self = _NSURLConnection$init$(self, _cmd, copy, delegate, usesCache, maxContentLength, startImmediately, connectionProperties)) != nil) {
    } return self;
}


@implementation NSURLConnection (CydiaHooks)

+ (void)setUpHooks {
    $NSURLConnection = objc_getClass("NSURLConnection");
    Method NSURLConnection$init$(class_getInstanceMethod($NSURLConnection, @selector(_initWithRequest:delegate:usesCache:maxContentLength:startImmediately:connectionProperties:)));
    if (NSURLConnection$init$ != NULL) {
        _NSURLConnection$init$ = reinterpret_cast<id (*)(NSURLConnection *, SEL, NSURLRequest *, id, BOOL, int64_t, BOOL, NSDictionary *)>(method_getImplementation(NSURLConnection$init$));
        method_setImplementation(NSURLConnection$init$, reinterpret_cast<IMP>(&$NSURLConnection$init$));
    }
}

@end
