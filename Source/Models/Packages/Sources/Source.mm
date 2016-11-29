//
//  Source.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Source.h"
#import "Profiling.hpp"
#import "NSString+Cydia.hpp"

@implementation Source

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

- (metaIndex *) metaIndex {
    return index_;
}

- (void) setMetaIndex:(metaIndex *)index inPool:(CYPool *)pool {
    trusted_ = index->IsTrusted();
    
    uri_.set(pool, index->GetURI());
    distribution_.set(pool, index->GetDist());
    type_.set(pool, index->GetType());
    
    debReleaseIndex *dindex(dynamic_cast<debReleaseIndex *>(index));
    if (dindex != NULL) {
        std::string file(dindex->MetaIndexURI(""));
        base_.set(pool, file);
        
        pkgAcquire acquire;
        _profile(Source$setMetaIndex$GetIndexes)
        dindex->GetIndexes(&acquire, true);
        _end
        _profile(Source$setMetaIndex$DescURI)
        for (pkgAcquire::ItemIterator item(acquire.ItemsBegin()); item != acquire.ItemsEnd(); item++) {
            std::string file((*item)->DescURI());
            files_.insert(file);
            if (file.length() < sizeof("Packages.bz2") || file.substr(file.length() - sizeof("Packages.bz2")) != "/Packages.bz2")
                continue;
            file = file.substr(0, file.length() - 4);
            files_.insert(file);
            files_.insert(file + ".gz");
            files_.insert(file + "Index");
        }
        _end
        
        FileFd fd;
        if (!fd.Open(dindex->MetaIndexFile("Release"), FileFd::ReadOnly))
            _error->Discard();
        else {
            pkgTagFile tags(&fd);
            
            pkgTagSection section;
            tags.Step(section);
            
            struct {
                const char *name_;
                CYString *value_;
            } names[] = {
                {"default-icon", &defaultIcon_},
                {"depiction", &depiction_},
                {"description", &description_},
                {"label", &label_},
                {"origin", &origin_},
                {"support", &support_},
                {"version", &version_},
            };
            
            for (size_t i(0); i != sizeof(names) / sizeof(names[0]); ++i) {
                const char *start, *end;
                
                if (section.Find(names[i].name_, start, end)) {
                    CYString &value(*names[i].value_);
                    value.set(pool, start, end - start);
                }
            }
        }
    }
    
    record_ = [Sources_ objectForKey:[self key]];
    
    NSURL *url([NSURL URLWithString:uri_]);
    
    host_ = [url host];
    if (host_ != nil)
        host_ = [host_ lowercaseString];
    
    if (host_ != nil)
        authority_ = host_;
    else
        authority_ = [url path];
}

- (Source *) initWithMetaIndex:(metaIndex *)index forDatabase:(Database *)database inPool:(CYPool *)pool {
    if ((self = [super init]) != nil) {
        era_ = [database era];
        database_ = database;
        index_ = index;
        
        _profile(Source$initWithMetaIndex$setMetaIndex)
        [self setMetaIndex:index inPool:pool];
        _end
    } return self;
}

- (NSString *) getField:(NSString *)name {
    @synchronized (database_) {
        if ([database_ era] != era_ || index_ == NULL)
            return nil;
        
        debReleaseIndex *dindex(dynamic_cast<debReleaseIndex *>(index_));
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
    return depiction_.empty() ? nil : [static_cast<id>(depiction_) stringByReplacingOccurrencesOfString:@"*" withString:package];
}

- (NSString *) supportForPackage:(NSString *)package {
    return support_.empty() ? nil : [static_cast<id>(support_) stringByReplacingOccurrencesOfString:@"*" withString:package];
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

- (BOOL) trusted {
    return trusted_;
}

- (NSString *) rooturi {
    return uri_;
}

- (NSString *) distribution {
    return distribution_;
}

- (NSString *) type {
    return type_;
}

- (NSString *) baseuri {
    return base_.empty() ? nil : (id) base_;
}

- (NSString *) iconuri {
    if (NSString *base = [self baseuri])
        return [base stringByAppendingString:@"CydiaIcon.png"];
    
    return nil;
}

- (NSURL *) iconURL {
    if (NSString *uri = [self iconuri])
        return [NSURL URLWithString:uri];
    return nil;
}

- (NSString *) key {
    return [NSString stringWithFormat:@"%@:%@:%@", (NSString *) type_, (NSString *) uri_, (NSString *) distribution_];
}

- (NSString *) host {
    return host_;
}

- (NSString *) name {
    return origin_.empty() ? (id) authority_ : origin_;
}

- (NSString *) shortDescription {
    return description_;
}

- (NSString *) label {
    return label_.empty() ? (id) authority_ : label_;
}

- (NSString *) origin {
    return origin_;
}

- (NSString *) version {
    return version_;
}

- (NSString *) defaultIcon {
    return defaultIcon_;
}

- (void) setDelegate:(NSObject<SourceDelegate> *)delegate {
    delegate_ = delegate;
}

- (bool) fetch {
    return !fetches_.empty();
}

- (void) setFetch:(bool)fetch forURI:(const char *)uri {
    if (!fetch) {
        if (fetches_.erase(uri) == 0)
            return;
    } else if (files_.find(uri) == files_.end())
        return;
    else if (!fetches_.insert(uri).second)
        return;
    
    [delegate_ performSelectorOnMainThread:@selector(setFetch:) withObject:[NSNumber numberWithBool:[self fetch]] waitUntilDone:NO];
}

- (void) resetFetch {
    fetches_.clear();
    [delegate_ performSelectorOnMainThread:@selector(setFetch:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
}

@end