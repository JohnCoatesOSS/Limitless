//
//  Source.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Source.h"
#import "Profiling.hpp"
#import "NSString+Cydia.hpp"
#import "APTSource-Private.h"

@interface Source ()

@property APTSource *modernSource;
@property metaIndex *metaIndex;
@property Database *database;
@property int databaseEra;
@property BOOL trusted;
@property NSString *distribution;
@property NSString *depiction;
@property NSString *shortDescription;
@property (nonatomic) NSString *label;
@property NSString *origin;
@property NSString *support;
@property NSString *version;
@property NSString *defaultIcon;
@property NSString *authority;
@property NSString *host;
@property NSString *type;
@property NSString *base;
@property (retain, strong) NSArray<NSURL *> *associatedURLs;

@property (retain, strong) NSString *uri;

@end

@implementation Source

// MARK: - Init

- (Source *)initWithMetaIndex:(metaIndex *)index
                   forDatabase:(Database *)database
                        inPool:(CYPool *)pool {
    if ((self = [super init]) != nil) {
        _modernSource = [[APTSource alloc] initWithMetaIndex:index];
        _databaseEra = [database era];
        _database = database;
        _metaIndex = index;
        
        _profile(Source$initWithMetaIndex$setMetaIndex)
        [self setMetaIndex:index inPool:pool];
        _end
    } return self;
}

- (void) setMetaIndex:(metaIndex *)index
               inPool:(CYPool *)pool {
    APTSource *modernSource = self.modernSource;
    self.trusted = modernSource.isTrusted;
    self.uri = modernSource.uri.absoluteString;
    self.distribution = modernSource.distribution;
    self.type = modernSource.type;
    self.base = modernSource.releaseBaseURL.absoluteString;
    self.associatedURLs = modernSource.associatedURLs;
    
    self.depiction = modernSource.depiction.absoluteString;
    self.defaultIcon = modernSource.icon.absoluteString;
    self.shortDescription = modernSource.shortDescription;
    self.label = modernSource.name;
    self.origin = modernSource.origin.absoluteString;
    self.support = modernSource.support;
    self.version = modernSource.version;
    
    record_ = [Sources_ objectForKey:[self key]];
    
    self.authority = modernSource.authority;
    self.host = modernSource.host;
}

- (NSString *) getField:(NSString *)name {
    @synchronized (self.database) {
        if ([self.database era] != self.databaseEra || self.metaIndex == NULL)
            return nil;
        
        debReleaseIndex *dindex(dynamic_cast<debReleaseIndex *>(self.metaIndex));
        if (dindex == NULL)
            return nil;
        
        FileFd fd;
        if (!fd.Open(dindex->MetaIndexFile("Release"), FileFd::ReadOnly)) {
            _error->Discard();
            return nil;
        }
        
        pkgTagFile tags(&fd);
        
        pkgTagSection section;
        tags.Step(section);
        
        const char *start, *end;
        if (!section.Find([name UTF8String], start, end))
            return (NSString *) [NSNull null];
        
        return [NSString stringWithString:[(NSString *) CYStringCreate(start, end - start) autorelease]];
    } }

- (NSComparisonResult) compareByName:(Source *)source {
    NSString *lhs = [self name];
    NSString *rhs = [source name];
    
    if ([lhs length] != 0 && [rhs length] != 0) {
        unichar lhc = [lhs characterAtIndex:0];
        unichar rhc = [rhs characterAtIndex:0];
        
        if (isalpha(lhc) && !isalpha(rhc))
            return NSOrderedAscending;
        else if (!isalpha(lhc) && isalpha(rhc))
            return NSOrderedDescending;
    }
    
    return [lhs compare:rhs options:LaxCompareOptions_];
}

- (NSString *) depictionForPackage:(NSString *)package {
    if (!self.depiction || self.depiction.length == 0) {
        return nil;
    }
    return [self.depiction stringByReplacingOccurrencesOfString:@"*"
                                                withString:package];
}

- (NSString *) supportForPackage:(NSString *)package {
    if (!self.support || self.support.length == 0) {
        return nil;
    }
    
    return [self.support stringByReplacingOccurrencesOfString:@"*"
                                                     withString:package];
}

- (NSArray *) sections {
    return record_ == nil ? (id) [NSNull null] : [record_ objectForKey:@"Sections"] ?: [NSArray array];
}

- (void) _addSection:(NSString *)section {
    if (record_ == nil)
        return;
    else if (NSMutableArray *sections = [record_ objectForKey:@"Sections"]) {
        if (![sections containsObject:section])
            [sections addObject:section];
    } else
        [record_ setObject:[NSMutableArray arrayWithObject:section] forKey:@"Sections"];
}

- (bool) addSection:(NSString *)section {
    if (record_ == nil)
        return false;
    
    [self performSelectorOnMainThread:@selector(_addSection:) withObject:section waitUntilDone:NO];
    return true;
}

- (void) _removeSection:(NSString *)section {
    if (record_ == nil)
        return;
    
    if (NSMutableArray *sections = [record_ objectForKey:@"Sections"])
        if ([sections containsObject:section])
            [sections removeObject:section];
}

- (bool) removeSection:(NSString *)section {
    if (record_ == nil)
        return false;
    
    [self performSelectorOnMainThread:@selector(_removeSection:) withObject:section waitUntilDone:NO];
    return true;
}

- (void) _remove {
    [Sources_ removeObjectForKey:[self key]];
}

- (bool) remove {
    bool value(record_ != nil);
    [self performSelectorOnMainThread:@selector(_remove) withObject:nil waitUntilDone:NO];
    return value;
}

- (NSDictionary *) record {
    return record_;
}

- (NSString *)rootURI {
    return self.uri;
}

- (NSString *) baseuri {
    return self.base;
}

- (NSString *) iconuri {
    if (NSString *base = self.base)
        return [base stringByAppendingPathComponent:@"CydiaIcon.png"];
    
    return nil;
}

- (NSURL *) iconURL {
    if (NSString *uri = [self iconuri])
        return [NSURL URLWithString:uri];
    return nil;
}

- (NSString *) key {
    return [NSString stringWithFormat:@"%@:%@:%@",
            self.type, self.uri, self.distribution];
}


- (NSString *) name {
    if (!self.origin || self.origin.length == 0) {
        return self.authority;
    }
    
    return self.origin;
}

- (NSString *) label {
    if (!_label || _label.length == 0) {
        return self.authority;
    } else {
        return _label;
    }
}

- (void) setDelegate:(NSObject<SourceDelegate> *)delegate {
    delegate_ = delegate;
}

- (bool) fetch {
    return !fetches_.empty();
}

- (void) setFetch:(bool)fetch forURI:(const char *)uri {
    NSURL *url = [NSURL URLWithString:@(uri)];
    BOOL isAssociatedURL = [self.associatedURLs containsObject:url];
    if (!fetch) {
        if (fetches_.erase(uri) == 0)
            return;
    } else if (!isAssociatedURL)
        return;
    else if (!fetches_.insert(uri).second)
        return;
    
    [delegate_ performSelectorOnMainThread:@selector(setFetch:)
                                withObject:@([self fetch])
                             waitUntilDone:NO];
}

- (void) resetFetch {
    fetches_.clear();
    [delegate_ performSelectorOnMainThread:@selector(setFetch:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
}

// MARK: - Exposing To Javascript

+ (NSString *) webScriptNameForSelector:(SEL)selector {
    if (false);
    else if (selector == @selector(addSection:))
        return @"addSection";
    else if (selector == @selector(getField:))
        return @"getField";
    else if (selector == @selector(removeSection:))
        return @"removeSection";
    else if (selector == @selector(remove))
        return @"remove";
    else
        return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"baseuri",
            @"distribution",
            @"host",
            @"key",
            @"iconuri",
            @"label",
            @"name",
            @"origin",
            @"rooturi",
            @"sections",
            @"shortDescription",
            @"trusted",
            @"type",
            @"version",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

@end
