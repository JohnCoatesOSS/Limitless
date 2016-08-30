//
//  CydiaRelation.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Apt.h"

@interface CydiaRelation : NSObject {
    _H<NSString> relationship_;
    _H<NSMutableArray> clauses_;
}

- (id) initWithIterator:(pkgCache::DepIterator &)dep;

- (NSString *) relationship;
- (NSArray *) clauses;

@end