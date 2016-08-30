//
//  CydiaClause.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Apt.h"

@class CydiaOperation;

@interface CydiaClause : NSObject {
    _H<NSString> package_;
    _H<CydiaOperation> version_;
}

- (id) initWithIterator:(pkgCache::DepIterator &)dep;

- (NSString *) package;
- (CydiaOperation *) version;

@end