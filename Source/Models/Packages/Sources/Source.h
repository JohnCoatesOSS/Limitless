//
//  Source.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CYString.hpp"
#import "Database.h"

@interface Source : NSObject {
    unsigned era_;
    Database *database_;
    metaIndex *index_;
    
    CYString depiction_;
    CYString description_;
    CYString label_;
    CYString origin_;
    CYString support_;
    
    CYString uri_;
    CYString distribution_;
    CYString type_;
    CYString base_;
    CYString version_;
    
    _H<NSString> host_;
    _H<NSString> authority_;
    
    CYString defaultIcon_;
    
    _H<NSMutableDictionary> record_;
    BOOL trusted_;
    
    std::set<std::string> fetches_;
    std::set<std::string> files_;
    _transient NSObject<SourceDelegate> *delegate_;
}

- (Source *) initWithMetaIndex:(metaIndex *)index
                   forDatabase:(Database *)database
                        inPool:(CYPool *)pool;

- (NSComparisonResult) compareByName:(Source *)source;

- (NSString *) depictionForPackage:(NSString *)package;
- (NSString *) supportForPackage:(NSString *)package;

- (metaIndex *) metaIndex;
- (NSDictionary *) record;
- (BOOL) trusted;
- (bool)isFavorited;

- (NSString *) rooturi;
- (NSString *) distribution;
- (NSString *) type;

- (NSString *) key;
- (NSString *) host;

- (NSString *) name;
- (NSString *) shortDescription;
- (NSString *) label;
- (NSString *) origin;
- (NSString *) version;

- (NSString *) defaultIcon;
- (NSURL *) iconURL;

- (void) setFetch:(bool)fetch forURI:(const char *)uri;
- (void) resetFetch;

- (void) setDelegate:(NSObject<SourceDelegate> *)delegate;
- (bool) fetch;

@end
