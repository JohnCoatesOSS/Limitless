//
//  CydiaRelation.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CydiaRelation.h"
#import <WebKit/DOMElement.h>
#import "CydiaClause.h"

@implementation CydiaRelation

- (id) initWithIterator:(pkgCache::DepIterator &)dep {
    if ((self = [super init]) != nil) {
        relationship_ = [NSString stringWithUTF8String:dep.DepType()];
        clauses_ = [NSMutableArray arrayWithCapacity:8];
        
        pkgCache::DepIterator start;
        pkgCache::DepIterator end;
        dep.GlobOr(start, end); // ++dep
        
        _forever {
            [clauses_ addObject:[[[CydiaClause alloc] initWithIterator:start] autorelease]];
            
            // yes, seriously. (wtf?)
            if (start == end)
                break;
            ++start;
        }
    } return self;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"clauses",
            @"relationship",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (NSString *) relationship {
    return relationship_;
}

- (NSArray *) clauses {
    return clauses_;
}

- (void) addClause:(CydiaClause *)clause {
    [clauses_ addObject:clause];
}

@end