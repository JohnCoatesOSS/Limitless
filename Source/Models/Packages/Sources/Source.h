//
//  Source.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CYString.hpp"
#import "Database.h"

@interface Source : NSObject {
    
    _H<NSMutableDictionary> record_;
    
    std::set<std::string> fetches_;
    std::set<std::string> files_;
    _transient NSObject<SourceDelegate> *delegate_;
}

@property (readonly) metaIndex *metaIndex;
@property (readonly) BOOL trusted;
@property (readonly, nonatomic) NSString *rootURI;
@property (readonly) NSString *distribution;
@property (readonly) NSString *type;
@property (readonly) NSString *host;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *label;
@property (readonly) NSString *origin;
@property (readonly) NSString *version;
@property (readonly) NSString *defaultIcon;
@property (readonly) NSArray<NSURL *> *associatedURLs;
@property (readonly, nonatomic) NSURL *iconURL;

- (Source *) initWithMetaIndex:(metaIndex *)index
                   forDatabase:(Database *)database
                        inPool:(CYPool *)pool;

- (NSComparisonResult) compareByName:(Source *)source;

- (NSString *) depictionForPackage:(NSString *)package;
- (NSString *) supportForPackage:(NSString *)package;

- (NSDictionary *) record;

- (NSString *) key;

- (void) setFetch:(bool)fetch forURI:(const char *)uri;
- (void) resetFetch;

- (void) setDelegate:(NSObject<SourceDelegate> *)delegate;
- (bool) fetch;

@end
