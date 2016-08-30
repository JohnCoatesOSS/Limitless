//
//  CydiaClause.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaClause.h"
#import "CydiaOperation.h"
#import <WebKit/DOMElement.h>

@implementation CydiaClause

- (id) initWithIterator:(pkgCache::DepIterator &)dep {
    if ((self = [super init]) != nil) {
        package_ = [NSString stringWithUTF8String:dep.TargetPkg().Name()];
        
        if (const char *version = dep.TargetVer())
            version_ = [[[CydiaOperation alloc] initWithOperator:dep.CompType() value:version] autorelease];
        else
            version_ = (id) [NSNull null];
    } return self;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"package",
            @"version",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (NSString *) package {
    return package_;
}

- (CydiaOperation *) version {
    return version_;
}

@end