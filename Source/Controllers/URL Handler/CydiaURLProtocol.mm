//
//  CydiaURLProtocol.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaURLProtocol.h"
#import "iPhonePrivate.h"
#import "Menes/Menes.h"
#import "CyteKit.h"
#import "Database.h"
#import "GeneralHelpers.h"
#import "Package.h"


@implementation CydiaURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request {
    NSURL *url([request URL]);
    if (url == nil)
        return NO;
    
    NSString *scheme([[url scheme] lowercaseString]);
    if (scheme != nil && [scheme isEqualToString:@"cydia"])
        return YES;
    if ([[url absoluteString] hasPrefix:@"about:cydia-"])
        return YES;
    
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) _returnPNGWithImage:(UIImage *)icon forRequest:(NSURLRequest *)request {
    id<NSURLProtocolClient> client([self client]);
    if (icon == nil)
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil]];
    else {
        NSData *data(UIImagePNGRepresentation(icon));
        
        NSURLResponse *response([[[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"image/png" expectedContentLength:-1 textEncodingName:nil] autorelease]);
        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [client URLProtocol:self didLoadData:data];
        [client URLProtocolDidFinishLoading:self];
    }
}

- (void) startLoading {
    id<NSURLProtocolClient> client([self client]);
    NSURLRequest *request([self request]);
    
    NSURL *url([request URL]);
    NSString *href([url absoluteString]);
    NSString *scheme([[url scheme] lowercaseString]);
    
    NSString *path;
    
    if ([scheme isEqualToString:@"cydia"])
        path = [href substringFromIndex:8];
    else if ([scheme isEqualToString:@"about"])
        path = [href substringFromIndex:12];
    else _assert(false);
    
    NSRange slash([path rangeOfString:@"/"]);
    
    NSString *command;
    if (slash.location == NSNotFound) {
        command = path;
        path = nil;
    } else {
        command = [path substringToIndex:slash.location];
        path = [path substringFromIndex:(slash.location + 1)];
    }
    
    Database *database([Database sharedInstance]);
    
    if (false);
    else if ([command isEqualToString:@"application-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        UIImage *icon(nil);
        
        if (icon == nil && $SBSCopyIconImagePNGDataForDisplayIdentifier != NULL) {
            NSData *data([$SBSCopyIconImagePNGDataForDisplayIdentifier(path) autorelease]);
            icon = [UIImage imageWithData:data];
        }
        
        if (icon == nil)
            if (NSString *file = SBSCopyIconImagePathForDisplayIdentifier(path))
                icon = [UIImage imageAtPath:file];
        
        if (icon == nil)
            icon = [UIImage imageNamed:@"unknown.png"];
        
        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"package-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        Package *package([database packageWithName:path]);
        if (package == nil)
            goto fail;
        [package parse];
        UIImage *icon([package icon]);
        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"uikit-image"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *icon(_UIImageWithName(path));
        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"section-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *icon([UIImage imageAtPath:[NSString stringWithFormat:@"%@/Sections/%@.png", App_, [path stringByReplacingOccurrencesOfString:@" " withString:@"_"]]]);
        if (icon == nil)
            icon = [UIImage imageNamed:@"unknown.png"];
        [self _returnPNGWithImage:icon forRequest:request];
    } else fail: {
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
    }
}

- (void) stopLoading {
}

@end