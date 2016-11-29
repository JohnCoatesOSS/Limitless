//
//  ProgressEvent.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "ProgressEvent.h"

#import "CancelStatus.hpp"
#import "CydiaStatus.hpp"
#import "Database.h"
#import "SourceStatus.hpp"

@implementation CydiaProgressEvent

+ (CydiaProgressEvent *) eventWithMessage:(NSString *)message ofType:(NSString *)type {
    return [[[CydiaProgressEvent alloc] initWithMessage:message ofType:type] autorelease];
}

+ (CydiaProgressEvent *) eventWithMessage:(NSString *)message ofType:(NSString *)type forPackage:(NSString *)package {
    CydiaProgressEvent *event([self eventWithMessage:message ofType:type]);
    [event setPackage:package];
    return event;
}

+ (CydiaProgressEvent *) eventWithMessage:(NSString *)message ofType:(NSString *)type forItemDesc:(pkgAcquire::ItemDesc &)desc {
    CydiaProgressEvent *event([self eventWithMessage:message ofType:type]);
    
    NSString *description([NSString stringWithUTF8String:desc.Description.c_str()]);
    NSArray *fields([description componentsSeparatedByString:@" "]);
    [event setItem:fields];
    
    if ([fields count] > 3) {
        [event setPackage:[fields objectAtIndex:2]];
        [event setVersion:[fields objectAtIndex:3]];
    }
    
    [event setURL:[NSString stringWithUTF8String:desc.URI.c_str()]];
    
    return event;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"item",
            @"message",
            @"package",
            @"type",
            @"url",
            @"version",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (id) initWithMessage:(NSString *)message ofType:(NSString *)type {
    if ((self = [super init]) != nil) {
        message_ = message;
        type_ = type;
    } return self;
}

- (NSString *) message {
    return message_;
}

- (NSString *) type {
    return type_;
}

- (NSArray *) item {
    return (id) item_ ?: [NSNull null];
}

- (void) setItem:(NSArray *)item {
    item_ = item;
}

- (NSString *) package {
    return (id) package_ ?: [NSNull null];
}

- (void) setPackage:(NSString *)package {
    package_ = package;
}

- (NSString *) url {
    return (id) url_ ?: [NSNull null];
}

- (void) setURL:(NSString *)url {
    url_ = url;
}

- (void) setVersion:(NSString *)version {
    version_ = version;
}

- (NSString *) version {
    return (id) version_ ?: [NSNull null];
}

- (NSString *) compound:(NSString *)value {
    if (value != nil) {
        NSString *mode(nil); {
            NSString *type([self type]);
            if ([type isEqualToString:kCydiaProgressEventTypeError])
                mode = UCLocalize("ERROR");
            else if ([type isEqualToString:kCydiaProgressEventTypeWarning])
                mode = UCLocalize("WARNING");
        }
        
        if (mode != nil)
            value = [NSString stringWithFormat:UCLocalize("COLON_DELIMITED"), mode, value];
    }
    
    return value;
}

- (NSString *) compoundMessage {
    return [self compound:[self message]];
}

- (NSString *) compoundTitle {
    NSString *title;
    
    if (package_ == nil)
        title = nil;
    else if (Package *package = [[Database sharedInstance] packageWithName:package_])
        title = [package name];
    else
        title = package_;
    
    return [self compound:title];
}

@end