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
@property (retain, strong) NSMutableDictionary *record;
@property (retain, strong) NSString *uri;
@property (retain, strong) NSArray<NSURL *> *associatedURLs;
@property NSSet<NSURL *> *urlsPendingFetch;

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
        _urlsPendingFetch = [NSSet set];
        
        [self setMetaIndex:index inPool:pool];
    } return self;
}

// MARK: - Setup

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
    
    self.record = [Sources_ objectForKey:self.key];
    
    self.authority = modernSource.authority;
    self.host = modernSource.host;
}

// MARK: - Accessing Fields

- (NSString *)getField:(NSString *)name {
    @synchronized (self.database) {
        BOOL sameDatabaseVersion = [self.database era] == self.databaseEra;
        if (!sameDatabaseVersion || self.metaIndex == NULL) {
            return nil;
        }
        
        debReleaseIndex *dindex(dynamic_cast<debReleaseIndex *>(self.metaIndex));
        if (dindex == NULL) {
            return nil;
        }
        
        FileFd fd;
        if (!fd.Open(dindex->MetaIndexFile("Release"), FileFd::ReadOnly)) {
            _error->Discard();
            return nil;
        }
        
        pkgTagFile tags(&fd);
        
        pkgTagSection section;
        tags.Step(section);
        
        const char *start, *end;
        if (!section.Find([name UTF8String], start, end)) {
            return (NSString *) [NSNull null];
        }
        return [NSString stringWithUTF8Bytes:start length:end - start];
    }
}

// MARK: - Relative URLs

- (NSString *)depictionForPackage:(NSString *)package {
    if (!self.depiction || self.depiction.length == 0) {
        return nil;
    }
    return [self.depiction stringByReplacingOccurrencesOfString:@"*"
                                                withString:package];
}

- (NSString *)supportForPackage:(NSString *)package {
    if (!self.support || self.support.length == 0) {
        return nil;
    }
    
    return [self.support stringByReplacingOccurrencesOfString:@"*"
                                                     withString:package];
}

// MARK: - Deletion

- (void)_remove {
    [Sources_ removeObjectForKey:self.key];
}

- (BOOL)remove {
    BOOL value = self.record != nil;
    [self performSelectorOnMainThread:@selector(_remove)
                           withObject:nil waitUntilDone:NO];
    return value;
}

// MARK: - Property Accessors

- (NSString *)rootURI {
    return self.uri;
}

- (NSURL *)iconURL {
    if (NSString *uri = [self iconuri])
        return [NSURL URLWithString:uri];
    return nil;
}

- (NSString *)key {
    return [NSString stringWithFormat:@"%@:%@:%@",
            self.type, self.uri, self.distribution];
}

- (NSString *)name {
    if (self.origin.length == 0) {
        return self.authority;
    }
    
    return self.origin;
}

- (NSString *)label {
    if (_label.length == 0) {
        return self.authority;
    } else {
        return _label;
    }
}

// MARK: - Fetching

- (BOOL)fetch {
    return self.urlsPendingFetch.count > 0;
}

- (void)setFetch:(BOOL)shouldAddToPending forURI:(const char *)uri {
    NSURL *url = [NSURL URLWithString:@(uri)];
    BOOL isAssociatedURL = [self.associatedURLs containsObject:url];
    if (!shouldAddToPending) {
        BOOL containsURL = [self.urlsPendingFetch containsObject:url];
        if (!containsURL) {
            return;
        }
        
        NSMutableSet *mutableURLs = self.urlsPendingFetch.mutableCopy;
        [mutableURLs removeObject:url];
        self.urlsPendingFetch = mutableURLs;
    } else if (!isAssociatedURL) {
        return;
    } else if (shouldAddToPending) {
        if ([self.urlsPendingFetch containsObject:url]) {
            return;
        }
        
        NSMutableSet *mutableURLs = self.urlsPendingFetch.mutableCopy;
        [mutableURLs addObject:url];
        self.urlsPendingFetch = mutableURLs;
    }
    
    [self.delegate performSelectorOnMainThread:@selector(setFetch:)
                                withObject:@([self fetch])
                             waitUntilDone:NO];
}

- (void)resetFetch {
    self.urlsPendingFetch = [NSSet set];
    [self.delegate performSelectorOnMainThread:@selector(setFetch:)
                                    withObject:@(FALSE) waitUntilDone:NO];
}

// MARK: - Sections

- (NSArray *)sections {
    if (!self.record) {
        return (id) [NSNull null];
    }
    
    NSArray *sections = self.record[@"Sections"];
    if (!sections) {
        return @[];
    }
    
    return sections;
}

- (void)_addSection:(NSString *)section {
    if (!self.record) {
        return;
    }
    
    NSMutableArray *sections = self.record[@"Sections"];
    if (sections) {
        if (![sections containsObject:section]) {
            [sections addObject:section];
        }
    } else {
        self.record[@"Sections"] = @[section].mutableCopy;
    }
    
}

- (BOOL)addSection:(NSString *)section {
    if (!self.record) {
        return FALSE;
    }
    
    [self performSelectorOnMainThread:@selector(_addSection:)
                           withObject:section waitUntilDone:NO];
    return FALSE;
}

- (void)_removeSection:(NSString *)section {
    if (!self.record) {
        return;
    }
    
    NSMutableArray *sections = self.record[@"Sections"];
    if (sections) {
        if ([sections containsObject:section]) {
            [sections removeObject:section];
        }
    }
}

- (BOOL)removeSection:(NSString *)section {
    if (!self.record) {
        return FALSE;
    }
    
    [self performSelectorOnMainThread:@selector(_removeSection:)
                           withObject:section waitUntilDone:NO];
    return true;
}

// MARK: - Exposing To Javascript

+ (NSString *)webScriptNameForSelector:(SEL)selector {
    if (selector == @selector(addSection:)) {
        return @"addSection";
    } else if (selector == @selector(getField:)) {
        return @"getField";
    } else if (selector == @selector(removeSection:)) {
        return @"removeSection";
    } else if (selector == @selector(remove)) {
        return @"remove";
    } else {
        return nil;
    }
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

+ (NSArray *)_attributeKeys {
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

- (NSArray *)attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)keyCString {
    NSString *key = @(keyCString);
    NSArray *attributeKeys = [self _attributeKeys];
    BOOL keyContainedInAttributes = [attributeKeys containsObject:key];
    BOOL superAllowsKey = [super isKeyExcludedFromWebScript:keyCString];
    
    return !keyContainedInAttributes && !superAllowsKey;
}

// MARK: - Javascript Only Properties

- (NSString *)baseuri {
    return self.base;
}

- (NSString *)iconuri {
    if (NSString *base = self.base) {
        return [base stringByAppendingPathComponent:@"CydiaIcon.png"];
    }
    
    return nil;
}

// MARK: - Comparisons

- (NSComparisonResult)compareByName:(Source *)source {
    NSString *lhs = self.name;
    NSString *rhs = source.name;
    
    if (lhs.length != 0 && rhs.length != 0) {
        unichar lhc = [lhs characterAtIndex:0];
        unichar rhc = [rhs characterAtIndex:0];
        
        if (isalpha(lhc) && !isalpha(rhc))
            return NSOrderedAscending;
        else if (!isalpha(lhc) && isalpha(rhc))
            return NSOrderedDescending;
    }
    
    return [lhs compare:rhs options:LaxCompareOptions_];
}

@end
