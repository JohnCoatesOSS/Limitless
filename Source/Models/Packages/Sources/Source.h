//
//  Source.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "CYString.hpp"
#import "Database.h"

@interface Source : NSObject

@property (readonly) metaIndex *metaIndex;
@property (readonly) BOOL trusted;
@property (readonly, nonatomic) NSString *rootURI;
@property (readonly) NSString *distribution;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *label;
@property (readonly) NSString *origin;
@property (readonly) NSString *version;
@property (readonly) NSString *defaultIcon;
@property (readonly, nonatomic) NSURL *iconURL;
@property (readonly, nonatomic) NSString *key;
@property (readonly) NSMutableDictionary *record;
@property (assign) NSObject <SourceDelegate> *delegate;

- (Source *)initWithMetaIndex:(metaIndex *)index
                  forDatabase:(Database *)database
                       inPool:(CYPool *)pool;

- (NSString *)depictionForPackage:(NSString *)package;
- (NSString *)supportForPackage:(NSString *)package;

- (void)setFetch:(BOOL)fetch forURI:(const char *)uri;
- (void)resetFetch;
- (BOOL)fetch;

- (NSComparisonResult)compareByName:(Source *)source;

@end
