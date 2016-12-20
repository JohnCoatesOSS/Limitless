//
//  APTSource.m
//  Limitless
//
//  Created on 12/5/16.
//

#import "Apt.h"
#import "APTSource-Private.h"

@interface APTSource ()

@property metaIndex *metaIndex;

@end

@implementation APTSource

- (instancetype)init {
    self = [super init];

    if (self) {

    }

    return self;
}

- (instancetype)initWithMetaIndex:(metaIndex *)metaIndex {
    self = [super init];
    
    if (self) {
        _metaIndex = metaIndex;
        [self hydrateWithMetaIndex:metaIndex];
    }
    
    return self;
}

// MARK: - Debugging

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@ %@>",
            NSStringFromClass([self class]),
            self.name,
            self.origin
            ];
}

// MARK- Private

- (void)hydrateWithMetaIndex:(nonnull metaIndex *)metaIndex {
    self.isTrusted = metaIndex->IsTrusted();
    
    string uri = metaIndex->GetURI();
    self.uri = [NSURL URLWithString:@(uri.c_str())];
    
    string distribution = metaIndex->GetDist();
    self.distribution = @(distribution.c_str());
    
    string type = metaIndex->GetType();
    self.type = @(type.c_str());
    
    NSLog(@"uri: %@, distribution: %@, type: %@", self.uri, self.distribution, self.type);
    
    debReleaseIndex *releaseIndex = dynamic_cast<debReleaseIndex *>(metaIndex);
    if (releaseIndex) {
        [self hydrateWithReleaseIndex:releaseIndex];
    } else {
        NSLog(@"Couldn't cast to release index");
    }
    
    self.host = self.uri.host.lowercaseString;
    if (self.host) {
        self.authority = self.host;
    } else {
        self.authority = self.uri.path;
    }
}

- (void)hydrateWithReleaseIndex:(nonnull debReleaseIndex *)releaseIndex {
    string baseURI = releaseIndex->MetaIndexURI("");
    self.releaseBaseURL = [NSURL URLWithString:@(baseURI.c_str())];
    self.associatedURLs = [self urlsAssociatedWithReleaseIndex:releaseIndex];
    
    FileFd fileDescriptor;
    string releaseFile = releaseIndex->MetaIndexFile("Release");
    BOOL fileOpened = fileDescriptor.Open(releaseFile, FileFd::ReadOnly);
    
    if (!fileOpened) {
        NSLog(@"Couldn't open release meta index at %s", releaseFile.c_str());
        NSError *error = [APTErrorController popError];
        if (error) {
            NSLog(@"Meta index error: %@", error);
        }
        
        return;
    }
    
    pkgTagFile tags = &fileDescriptor;
    pkgTagSection section;
    tags.Step(section);
    
    self.icon = [self urlFromTagSection:&section tag:@"default-icon"];
    self.depiction = [self urlFromTagSection:&section tag:@"depiction"];
    self.shortDescription = [self stringFromTagSection:&section tag:@"description"];
    self.name = [self stringFromTagSection:&section tag:@"label"];
    self.origin = [self urlFromTagSection:&section tag:@"origin"];
    self.support = [self stringFromTagSection:&section tag:@"support"];
    self.version = [self stringFromTagSection:&section tag:@"version"];
}

- (NSURL *)urlFromTagSection:(pkgTagSection *)section
                         tag:(NSString *)tag {
    NSString *tagValue = [self stringFromTagSection:section
                                                tag:tag];
    if (!tagValue) {
        return nil;
    } else {
        return [NSURL URLWithString:tagValue];
    }
}

- (NSString *)stringFromTagSection:(pkgTagSection *)section
                               tag:(NSString *)tag {
    string tagValue = section->FindS(tag.UTF8String);
    if (tagValue.empty()) {
        return nil;
    } else {
        return @(tagValue.c_str());
    }
}

- (NSArray *)urlsAssociatedWithReleaseIndex:(nonnull debReleaseIndex*)releaseIndex {
    pkgAcquire acquire;
    bool getAllIndexes = true;
    releaseIndex->GetIndexes(&acquire, getAllIndexes);
    
    pkgAcquire::ItemIterator itemIndex = acquire.ItemsBegin();
    NSMutableArray *urls = [NSMutableArray new];
    
    for (;itemIndex != acquire.ItemsEnd(); itemIndex += 1) {
        pkgAcquire::Item *item = *itemIndex;
        string descriptionURIString = item->DescURI();
        NSString *descriptionURI = @(descriptionURIString.c_str());
        NSURL *url = [NSURL URLWithString:descriptionURI];
        [urls addObject:url];
        
        if (![url.lastPathComponent isEqualToString:@"Packages.bz2"]) {
            continue;
        }
        NSURL *baseURL = [url URLByDeletingLastPathComponent];
        [urls addObject:[baseURL URLByAppendingPathComponent:@"Packages"]];
        [urls addObject:[baseURL URLByAppendingPathComponent:@"Packages.gz"]];
        [urls addObject:[baseURL URLByAppendingPathComponent:@"PackagesIndex"]];
    }
    return urls;
}


@end
