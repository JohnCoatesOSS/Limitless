//
//  CydiaWebViewController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaWebViewController.h"
#import "Networking.h"
#import "SystemGlobals.h"

@implementation CydiaWebViewController

- (NSURL *)navigationURL {
    if (NSURLRequest *request = self.request) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://url/%@", [[request URL] absoluteString]]];
    } else {
        return nil;
    }
}

+ (void) _initialize {
    [super _initialize];
    
    Diversions_ = [NSMutableSet setWithCapacity:0];
}

+ (void) addDiversion:(Diversion *)diversion {
    [Diversions_ addObject:diversion];
}

- (void) webView:(WebView *)view didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:view didClearWindowObject:window forFrame:frame];
    [CydiaWebViewController didClearWindowObject:window forFrame:frame withCydia:cydia_];
}

+ (void) didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame withCydia:(CydiaObject *)cydia {
    WebDataSource *source([frame dataSource]);
    NSURLResponse *response([source response]);
    NSURL *url([response URL]);
    NSString *scheme([[url scheme] lowercaseString]);
    
    bool bridged(false);
    
    @synchronized (HostConfig_) {
        if ([scheme isEqualToString:@"file"])
            bridged = true;
        else// if ([scheme isEqualToString:@"https"])
            if ([BridgedHosts_ containsObject:[url host]])
                bridged = true;
    }
    
    if (bridged)
        [window setValue:cydia forKey:@"cydia"];
}

- (void) _setupMail:(MFMailComposeViewController *)controller {
    [controller addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/cydia.log"]
                         mimeType:@"text/plain" fileName:@"cydia.log"];
    
    NSString *dpkgOutput = [LMXLaunchProcess launchProcessAtPath:@"/usr/bin/dpkg"
                                                   withArguments:@"-l", nil];
    [controller addAttachmentData:[dpkgOutput dataUsingEncoding:NSUTF8StringEncoding]
                         mimeType:@"text/plain"
                         fileName:@"dpkgl.log"];
}

- (NSURL *) URLWithURL:(NSURL *)url {
    return [Diversion divertURL:url];
}

- (NSURLRequest *) webView:(WebView *)view resource:(id)resource willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)source {
    return [CydiaWebViewController requestWithHeaders:[super webView:view resource:resource willSendRequest:request redirectResponse:response fromDataSource:source]];
}

- (NSURLRequest *) webThreadWebView:(WebView *)view resource:(id)resource willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)source {
    return [CydiaWebViewController requestWithHeaders:[super webThreadWebView:view resource:resource willSendRequest:request redirectResponse:response fromDataSource:source]];
}

+ (NSURLRequest *) requestWithHeaders:(NSURLRequest *)request {
    NSMutableURLRequest *copy([[request mutableCopy] autorelease]);
    
    NSURL *url([copy URL]);
    NSString *href([url absoluteString]);
    NSString *host([url host]);
    
    if ([href hasPrefix:@"https://cydia.saurik.com/TSS/"]) {
        if (NSString *agent = [copy valueForHTTPHeaderField:@"X-User-Agent"]) {
            [copy setValue:agent forHTTPHeaderField:@"User-Agent"];
            [copy setValue:nil forHTTPHeaderField:@"X-User-Agent"];
        }
        
        [copy setValue:nil forHTTPHeaderField:@"Referer"];
        [copy setValue:nil forHTTPHeaderField:@"Origin"];
        
        [copy setURL:[NSURL URLWithString:[@"http://gs.apple.com/TSS/" stringByAppendingString:[href substringFromIndex:29]]]];
        return copy;
    }
    
    if ([copy valueForHTTPHeaderField:@"X-Cydia-Cf"] == nil)
        [copy setValue:[NSString stringWithFormat:@"%.2f", kCFCoreFoundationVersionNumber] forHTTPHeaderField:@"X-Cydia-Cf"];
    if (Machine_ != NULL && [copy valueForHTTPHeaderField:@"X-Machine"] == nil)
        [copy setValue:[NSString stringWithUTF8String:Machine_] forHTTPHeaderField:@"X-Machine"];
    
    bool bridged; @synchronized (HostConfig_) {
        bridged = [BridgedHosts_ containsObject:host];
    }
    
    if ([url isCydiaSecure] && bridged && UniqueID_ != nil && [copy valueForHTTPHeaderField:@"X-Cydia-Id"] == nil)
        [copy setValue:UniqueID_ forHTTPHeaderField:@"X-Cydia-Id"];
    
    return copy;
}

- (void) setDelegate:(id)delegate {
    [super setDelegate:delegate];
    [cydia_ setDelegate:delegate];
}

- (NSString *) applicationNameForUserAgent {
    return UserAgent_;
}

- (id) init {
    if ((self = [super initWithWidth:0 ofClass:[CydiaWebViewController class]]) != nil) {
        cydia_ = [[[CydiaObject alloc] initWithDelegate:self.indirect] autorelease];
    } return self;
}

@end
