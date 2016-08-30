//
//  CYURLCache.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CYURLCache.h"
#import "Flags.h"
#import "Networking.h"

@implementation CYURLCache

- (void) logEvent:(NSString *)event forRequest:(NSURLRequest *)request {
#if !ForRelease
    if (false);
    else if ([event isEqualToString:@"no-cache"])
        event = @"!!!";
    else if ([event isEqualToString:@"store"])
        event = @">>>";
    else if ([event isEqualToString:@"invalid"])
        event = @"???";
    else if ([event isEqualToString:@"memory"])
        event = @"mem";
    else if ([event isEqualToString:@"disk"])
        event = @"ssd";
    else if ([event isEqualToString:@"miss"])
        event = @"---";
    
    NSLog(@"%@: %@", event, [[request URL] absoluteString]);
#endif
}

- (void) storeCachedResponse:(NSCachedURLResponse *)cached forRequest:(NSURLRequest *)request {
    if (NSURLResponse *response = [cached response])
        if (NSString *mime = [response MIMEType])
            if ([mime isEqualToString:@"text/cache-manifest"]) {
                NSURL *url([response URL]);
                
#if !ForRelease
                NSLog(@"###: %@", [url absoluteString]);
#endif
                
                @synchronized (HostConfig_) {
                    [CachedURLs_ addObject:url];
                }
            }
    
    [super storeCachedResponse:cached forRequest:request];
}

- (void) createDiskCachePath {
    [super createDiskCachePath];
}

@end