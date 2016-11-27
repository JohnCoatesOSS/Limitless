//
//  CydiaObject.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import <WebKit/DOMHTMLIFrameElement.h>
#import "System.h"

#import "CydiaObject.h"
#import "Package.h"
#import "GeneralGlobals.h"
#import "SystemGlobals.h"
#import "SystemHelpers.h"
#import "DisplayHelpers.hpp"
#import "CydiaWebViewController.h"
#import "Networking.h"

@implementation CydiaObject

- (id) initWithDelegate:(IndirectDelegate *)indirect {
    if ((self = [super init]) != nil) {
        indirect_ = (CyteWebViewController *) indirect;
    } return self;
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"bbsnum",
            @"build",
            @"coreFoundationVersionNumber",
            @"device",
            @"ecid",
            @"firmware",
            @"hostname",
            @"idiom",
            @"mcc",
            @"mnc",
            @"model",
            @"operator",
            @"role",
            @"serial",
            @"version",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (NSString *) version {
    return Cydia_;
}

- (NSString *) build {
    return System_;
}

- (NSString *) coreFoundationVersionNumber {
    return [NSString stringWithFormat:@"%.2f", kCFCoreFoundationVersionNumber];
}

- (NSString *) device {
    return UniqueIdentifier();
}

- (NSString *) firmware {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *) hostname {
    return [[UIDevice currentDevice] name];
}

- (NSString *) idiom {
    if ([Device isPad]) {
        return @"ipad";
    } else {
        return @"iphone";
    }
}

- (NSString *) mcc {
    if (CFStringRef (*$CTSIMSupportCopyMobileSubscriberCountryCode)(CFAllocatorRef) = reinterpret_cast<CFStringRef (*)(CFAllocatorRef)>(dlsym(RTLD_DEFAULT, "CTSIMSupportCopyMobileSubscriberCountryCode")))
        return [(NSString *) (*$CTSIMSupportCopyMobileSubscriberCountryCode)(kCFAllocatorDefault) autorelease];
    return nil;
}

- (NSString *) mnc {
    if (CFStringRef (*$CTSIMSupportCopyMobileSubscriberNetworkCode)(CFAllocatorRef) = reinterpret_cast<CFStringRef (*)(CFAllocatorRef)>(dlsym(RTLD_DEFAULT, "CTSIMSupportCopyMobileSubscriberNetworkCode")))
        return [(NSString *) (*$CTSIMSupportCopyMobileSubscriberNetworkCode)(kCFAllocatorDefault) autorelease];
    return nil;
}

- (NSString *) operator {
    if (CFStringRef (*$CTRegistrationCopyOperatorName)(CFAllocatorRef) = reinterpret_cast<CFStringRef (*)(CFAllocatorRef)>(dlsym(RTLD_DEFAULT, "CTRegistrationCopyOperatorName")))
        return [(NSString *) (*$CTRegistrationCopyOperatorName)(kCFAllocatorDefault) autorelease];
    return nil;
}

- (NSString *) bbsnum {
    return (id) BBSNum_ ?: [NSNull null];
}

- (NSString *) ecid {
    return (id) ChipID_ ?: [NSNull null];
}

- (NSString *) serial {
    return SerialNumber_;
}

- (NSString *) role {
    return (id) [NSNull null];
}

- (NSString *) model {
    return [NSString stringWithUTF8String:Machine_];
}

+ (NSString *) webScriptNameForSelector:(SEL)selector {
    if (false);
    else if (selector == @selector(addBridgedHost:))
        return @"addBridgedHost";
    else if (selector == @selector(addInsecureHost:))
        return @"addInsecureHost";
    else if (selector == @selector(addInternalRedirect::))
        return @"addInternalRedirect";
    else if (selector == @selector(addPipelinedHost:scheme:))
        return @"addPipelinedHost";
    else if (selector == @selector(addSource:::))
        return @"addSource";
    else if (selector == @selector(addTrivialSource:))
        return @"addTrivialSource";
    else if (selector == @selector(close))
        return @"close";
    else if (selector == @selector(du:))
        return @"du";
    else if (selector == @selector(stringWithFormat:arguments:))
        return @"format";
    else if (selector == @selector(getAllSources))
        return @"getAllSources";
    else if (selector == @selector(getApplicationInfo:value:))
        return @"getApplicationInfoValue";
    else if (selector == @selector(getDisplayIdentifiers))
        return @"getDisplayIdentifiers";
    else if (selector == @selector(getLocalizedNameForDisplayIdentifier:))
        return @"getLocalizedNameForDisplayIdentifier";
    else if (selector == @selector(getKernelNumber:))
        return @"getKernelNumber";
    else if (selector == @selector(getKernelString:))
        return @"getKernelString";
    else if (selector == @selector(getInstalledPackages))
        return @"getInstalledPackages";
    else if (selector == @selector(getIORegistryEntry::))
        return @"getIORegistryEntry";
    else if (selector == @selector(getLocaleIdentifier))
        return @"getLocaleIdentifier";
    else if (selector == @selector(getPreferredLanguages))
        return @"getPreferredLanguages";
    else if (selector == @selector(getPackageById:))
        return @"getPackageById";
    else if (selector == @selector(getMetadataKeys))
        return @"getMetadataKeys";
    else if (selector == @selector(getMetadataValue:))
        return @"getMetadataValue";
    else if (selector == @selector(getSessionValue:))
        return @"getSessionValue";
    else if (selector == @selector(installPackages:))
        return @"installPackages";
    else if (selector == @selector(isReachable:))
        return @"isReachable";
    else if (selector == @selector(localizedStringForKey:value:table:))
        return @"localize";
    else if (selector == @selector(popViewController:))
        return @"popViewController";
    else if (selector == @selector(refreshSources))
        return @"refreshSources";
    else if (selector == @selector(registerFrame:))
        return @"registerFrame";
    else if (selector == @selector(removeButton))
        return @"removeButton";
    else if (selector == @selector(saveConfig))
        return @"saveConfig";
    else if (selector == @selector(setMetadataValue::))
        return @"setMetadataValue";
    else if (selector == @selector(setSessionValue::))
        return @"setSessionValue";
    else if (selector == @selector(substitutePackageNames:))
        return @"substitutePackageNames";
    else if (selector == @selector(scrollToBottom:))
        return @"scrollToBottom";
    else if (selector == @selector(setAllowsNavigationAction:))
        return @"setAllowsNavigationAction";
    else if (selector == @selector(setBadgeValue:))
        return @"setBadgeValue";
    else if (selector == @selector(setButtonImage:withStyle:toFunction:))
        return @"setButtonImage";
    else if (selector == @selector(setButtonTitle:withStyle:toFunction:))
        return @"setButtonTitle";
    else if (selector == @selector(setHidesBackButton:))
        return @"setHidesBackButton";
    else if (selector == @selector(setHidesNavigationBar:))
        return @"setHidesNavigationBar";
    else if (selector == @selector(setNavigationBarStyle:))
        return @"setNavigationBarStyle";
    else if (selector == @selector(setNavigationBarTintRed:green:blue:alpha:))
        return @"setNavigationBarTintColor";
    else if (selector == @selector(setPasteboardString:))
        return @"setPasteboardString";
    else if (selector == @selector(setPasteboardURL:))
        return @"setPasteboardURL";
    else if (selector == @selector(setScrollAlwaysBounceVertical:))
        return @"setScrollAlwaysBounceVertical";
    else if (selector == @selector(setScrollIndicatorStyle:))
        return @"setScrollIndicatorStyle";
    else if (selector == @selector(setToken:))
        return @"setToken";
    else if (selector == @selector(setViewportWidth:))
        return @"setViewportWidth";
    else if (selector == @selector(statfs:))
        return @"statfs";
    else if (selector == @selector(supports:))
        return @"supports";
    else if (selector == @selector(unload))
        return @"unload";
    else
        return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

- (BOOL) supports:(NSString *)feature {
    return [feature isEqualToString:@"window.open"];
}

- (void) unload {
    [delegate_ performSelectorOnMainThread:@selector(unloadData) withObject:nil waitUntilDone:NO];
}

- (void) setScrollAlwaysBounceVertical:(NSNumber *)value {
    [indirect_ performSelectorOnMainThread:@selector(setScrollAlwaysBounceVerticalNumber:) withObject:value waitUntilDone:NO];
}

- (void) setScrollIndicatorStyle:(NSString *)style {
    [indirect_ performSelectorOnMainThread:@selector(setScrollIndicatorStyleWithName:) withObject:style waitUntilDone:NO];
}

- (void) addInternalRedirect:(NSString *)from :(NSString *)to {
    [CydiaWebViewController performSelectorOnMainThread:@selector(addDiversion:) withObject:[[[Diversion alloc] initWithFrom:from to:to] autorelease] waitUntilDone:NO];
}

- (NSDictionary *) getApplicationInfo:(NSString *)display value:(NSString *)key {
    char path[1024];
    if (SBBundlePathForDisplayIdentifier(SBSSpringBoardServerPort(), [display UTF8String], path) != 0)
        return (id) [NSNull null];
    NSDictionary *info([NSDictionary dictionaryWithContentsOfFile:[[NSString stringWithUTF8String:path] stringByAppendingString:@"/Info.plist"]]);
    if (info == nil)
        return (id) [NSNull null];
    return [info objectForKey:key];
}

- (NSArray *) getDisplayIdentifiers {
    if ([Device isSimulator]) {
        return @[@"com.facebook.Messenger"];
    }
    id set = [(id)SBSCopyApplicationDisplayIdentifiers(0, 0) autorelease];
    if (set == nil)
        return [NSArray array];
    
    if ([set isKindOfClass:[NSArray class]]) {
        return set;
    }
    if ([set isKindOfClass:[NSSet class]]) {
        return [set allObjects];
    }
    
    return [NSArray array];
}

- (NSString *) getLocalizedNameForDisplayIdentifier:(NSString *)identifier {
    if ([Device isSimulator]) {
        return @"Facebook Messenger";
    }
    return [SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier) autorelease] ?: (id) [NSNull null];
}

- (NSNumber *) getKernelNumber:(NSString *)name {
    const char *string([name UTF8String]);
    
    size_t size;
    if (sysctlbyname(string, NULL, &size, NULL, 0) == -1)
        return (id) [NSNull null];
    
    if (size != sizeof(int))
        return (id) [NSNull null];
    
    int value;
    if (sysctlbyname(string, &value, &size, NULL, 0) == -1)
        return (id) [NSNull null];
    
    return [NSNumber numberWithInt:value];
}

- (NSString *) getKernelString:(NSString *)name {
    const char *string([name UTF8String]);
    
    size_t size;
    if (sysctlbyname(string, NULL, &size, NULL, 0) == -1)
        return (id) [NSNull null];
    
    char value[size + 1];
    if (sysctlbyname(string, value, &size, NULL, 0) == -1)
        return (id) [NSNull null];
    
    // XXX: just in case you request something ludicrous
    value[size] = '\0';
    
    return [NSString stringWithUTF8String:value];
}

- (NSObject *) getIORegistryEntry:(NSString *)path :(NSString *)entry {
    NSObject *value(CYIOGetValue([path UTF8String], entry));
    
    if (value != nil)
        if ([value isKindOfClass:[NSData class]])
            value = CYHex((NSData *) value);
    
    return value;
}

- (NSArray *) getMetadataKeys {
    @synchronized (Values_) {
        return [Values_ allKeys];
    } }

- (void) registerFrame:(DOMHTMLIFrameElement *)iframe {
    WebFrame *frame([iframe contentFrame]);
    [indirect_ registerFrame:frame];
}

- (id) getMetadataValue:(NSString *)key {
    @synchronized (Values_) {
        return [Values_ objectForKey:key];
    } }

- (void) setMetadataValue:(NSString *)key :(NSString *)value {
    @synchronized (Values_) {
        if (value == nil || value == (id) [WebUndefined undefined] || value == (id) [NSNull null])
            [Values_ removeObjectForKey:key];
        else
            [Values_ setObject:value forKey:key];
    } }

- (id) getSessionValue:(NSString *)key {
    @synchronized (SessionData_) {
        return [SessionData_ objectForKey:key];
    } }

- (void) setSessionValue:(NSString *)key :(NSString *)value {
    @synchronized (SessionData_) {
        if (value == (id) [WebUndefined undefined])
            [SessionData_ removeObjectForKey:key];
        else
            [SessionData_ setObject:value forKey:key];
    } }

- (void) addBridgedHost:(NSString *)host {
    @synchronized (HostConfig_) {
        [BridgedHosts_ addObject:host];
    } }

- (void) addInsecureHost:(NSString *)host {
    @synchronized (HostConfig_) {
        [InsecureHosts_ addObject:host];
    } }

- (void) addPipelinedHost:(NSString *)host scheme:(NSString *)scheme {
    @synchronized (HostConfig_) {
        if (scheme != (id) [WebUndefined undefined])
            host = [NSString stringWithFormat:@"%@:%@", [scheme lowercaseString], host];
        
        [PipelinedHosts_ addObject:host];
    } }

- (void) popViewController:(NSNumber *)value {
    if (value == (id) [WebUndefined undefined])
        value = [NSNumber numberWithBool:YES];
    [indirect_ performSelectorOnMainThread:@selector(popViewControllerWithNumber:) withObject:value waitUntilDone:NO];
}

- (void) addSource:(NSString *)href :(NSString *)distribution :(WebScriptObject *)sections {
    NSMutableArray *array([NSMutableArray arrayWithCapacity:[sections count]]);
    
    for (NSString *section in sections)
        [array addObject:section];
    
    [delegate_ performSelectorOnMainThread:@selector(addSource:) withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                             @"deb", @"Type",
                                                                             href, @"URI",
                                                                             distribution, @"Distribution",
                                                                             array, @"Sections",
                                                                             nil] waitUntilDone:NO];
}

- (BOOL) addTrivialSource:(NSString *)href {
    href = VerifySource(href);
    if (href == nil)
        return NO;
    [delegate_ performSelectorOnMainThread:@selector(addTrivialSource:) withObject:href waitUntilDone:NO];
    return YES;
}

- (void) refreshSources {
    [delegate_ performSelectorOnMainThread:@selector(syncData) withObject:nil waitUntilDone:NO];
}

- (void) saveConfig {
    [delegate_ performSelectorOnMainThread:@selector(_saveConfig) withObject:nil waitUntilDone:NO];
}

- (NSArray *) getAllSources {
    return [[Database sharedInstance] sources];
}

- (NSArray *) getInstalledPackages {
    Database *database([Database sharedInstance]);
    @synchronized (database) {
        NSArray *packages([database packages]);
        NSMutableArray *installed([NSMutableArray arrayWithCapacity:1024]);
        for (Package *package in packages)
            if (![package uninstalled])
                [installed addObject:package];
        return installed;
    } }

- (Package *) getPackageById:(NSString *)id {
    if (Package *package = [[Database sharedInstance] packageWithName:id]) {
        [package parse];
        return package;
    } else
        return (Package *) [NSNull null];
}

- (NSString *) getLocaleIdentifier {
    return Locale_ == NULL ? (NSString *) [NSNull null] : (NSString *) CFLocaleGetIdentifier(Locale_);
}

- (NSArray *) getPreferredLanguages {
    return Languages_;
}

- (NSArray *) statfs:(NSString *)path {
    struct statfs stat;
    
    if (path == nil || statfs([path UTF8String], &stat) == -1)
        return nil;
    
    return [NSArray arrayWithObjects:
            @(stat.f_bsize),
            @(stat.f_blocks),
            @(stat.f_bfree),
            nil];
}

- (NSNumber *) du:(NSString *)path {
    NSNumber *value(nil);
    
    FILE *du(popen([[NSString stringWithFormat:@"/Applications/Limitless.app/runAsSuperuser /usr/libexec/cydia/du -ks %@", ShellEscape(path)] UTF8String], "r"));
    if (du != NULL) {
        char line[1024];
        while (fgets(line, sizeof(line), du) != NULL) {
            size_t length(strlen(line));
            while (length != 0 && line[length - 1] == '\n')
                line[--length] = '\0';
            if (char *tab = strchr(line, '\t')) {
                *tab = '\0';
                value = [NSNumber numberWithUnsignedLong:strtoul(line, NULL, 0)];
            }
        }
        pclose(du);
    }
    
    return value;
}

- (void) close {
    [indirect_ performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
}

- (NSNumber *) isReachable:(NSString *)name {
    return [NSNumber numberWithBool:IsReachable([name UTF8String])];
}

- (void) installPackages:(NSArray *)packages {
    [delegate_ performSelectorOnMainThread:@selector(installPackages:) withObject:packages waitUntilDone:NO];
}

- (NSString *) substitutePackageNames:(NSString *)message {
    NSMutableArray *words([[[message componentsSeparatedByString:@" "] mutableCopy] autorelease]);
    for (size_t i(0), e([words count]); i != e; ++i) {
        NSString *word([words objectAtIndex:i]);
        if (Package *package = [[Database sharedInstance] packageWithName:word])
            [words replaceObjectAtIndex:i withObject:[package name]];
    }
    
    return [words componentsJoinedByString:@" "];
}

- (void) removeButton {
    [indirect_ removeButton];
}

- (void) setButtonImage:(NSString *)button withStyle:(NSString *)style toFunction:(id)function {
    [indirect_ setButtonImage:button withStyle:style toFunction:function];
}

- (void) setButtonTitle:(NSString *)button withStyle:(NSString *)style toFunction:(id)function {
    [indirect_ setButtonTitle:button withStyle:style toFunction:function];
}

- (void) setBadgeValue:(id)value {
    [indirect_ performSelectorOnMainThread:@selector(setBadgeValue:) withObject:value waitUntilDone:NO];
}

- (void) setAllowsNavigationAction:(NSString *)value {
    [indirect_ performSelectorOnMainThread:@selector(setAllowsNavigationActionByNumber:) withObject:value waitUntilDone:NO];
}

- (void) setHidesBackButton:(NSString *)value {
    [indirect_ performSelectorOnMainThread:@selector(setHidesBackButtonByNumber:) withObject:value waitUntilDone:NO];
}

- (void) setHidesNavigationBar:(NSString *)value {
    [indirect_ performSelectorOnMainThread:@selector(setHidesNavigationBarByNumber:) withObject:value waitUntilDone:NO];
}

- (void) setNavigationBarStyle:(NSString *)value {
    [indirect_ performSelectorOnMainThread:@selector(setNavigationBarStyle:) withObject:value waitUntilDone:NO];
}

- (void) setNavigationBarTintRed:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue alpha:(NSNumber *)alpha {
    float opacity(alpha == (id) [WebUndefined undefined] ? 1 : [alpha floatValue]);
    UIColor *color([UIColor colorWithRed:[red floatValue] green:[green floatValue] blue:[blue floatValue] alpha:opacity]);
    [indirect_ performSelectorOnMainThread:@selector(setNavigationBarTintColor:) withObject:color waitUntilDone:NO];
}

- (void) setPasteboardString:(NSString *)value {
    [[objc_getClass("UIPasteboard") generalPasteboard] setString:value];
}

- (void) setPasteboardURL:(NSString *)value {
    [[objc_getClass("UIPasteboard") generalPasteboard] setURL:[NSURL URLWithString:value]];
}

- (void) setToken:(NSString *)token {
    // XXX: the website expects this :/
}

- (void) scrollToBottom:(NSNumber *)animated {
    [indirect_ performSelectorOnMainThread:@selector(scrollToBottomAnimated:) withObject:animated waitUntilDone:NO];
}

- (void) setViewportWidth:(float)width {
    [indirect_ setViewportWidthOnMainThread:width];
}

- (NSString *) stringWithFormat:(NSString *)format arguments:(WebScriptObject *)arguments {
    NSLog(@"SWF:\"%@\" A:%@", format, [arguments description]);
#if (TARGET_OS_SIMULATOR)
    assert(0);
    // TODO: fix casting error
    // Reinterpret_cast from 'id *' to 'va_list' (aka '__builtin_va_list') is not allowed
    return @"";
#else
    unsigned count([arguments count]);
    id values[count];
    for (unsigned i(0); i != count; ++i)
        values[i] = [arguments objectAtIndex:i];
    return [[[NSString alloc] initWithFormat:format arguments:reinterpret_cast<va_list>(values)] autorelease];
#endif
}

- (NSString *) localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)table {
    if (reinterpret_cast<id>(value) == [WebUndefined undefined])
        value = nil;
    if (reinterpret_cast<id>(table) == [WebUndefined undefined])
        table = nil;
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:table];
}

@end
