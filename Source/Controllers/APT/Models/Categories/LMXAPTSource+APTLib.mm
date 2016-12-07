//
//  LMXAPTSource+APTLib
//  Limitless
//
//  Created on 12/5/16.
//

#import "LMXAPTSource+APTLib.h"

@implementation LMXAPTSource (APTLib)

- (instancetype)initWithMetaIndex:(metaIndex *)metaIndex {
    self = [super init];

    if (self) {
        [self hydrateWithMetaIndex:metaIndex];
    }

    return self;
}

- (void)hydrateWithMetaIndex:(nonnull metaIndex *)metaIndex {
    self.isTrusted = metaIndex->IsTrusted();
    
    string uri = metaIndex->GetURI();
    self.uri = [NSURL URLWithString:@(uri.c_str())];
    
    string distribution = metaIndex->GetDist();
    self.distribution = @(distribution.c_str());
    
    string type = metaIndex->GetType();
    self.type = @(type.c_str());
    
    debReleaseIndex *releaseIndex = dynamic_cast<debReleaseIndex *>(metaIndex);
    if (releaseIndex) {
        [self hydrateWithReleaseIndex:releaseIndex];
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
    self.files = [self filesAssociatedWithReleaseIndex:releaseIndex];
    
    FileFd fileDescriptor;
    string releaseFile = releaseIndex->MetaIndexFile("Release");
    BOOL fileOpened = fileDescriptor.Open(releaseFile, FileFd::ReadOnly);
    
    if (!fileOpened) {
        NSLog(@"Couldn't open release meta index at %s", releaseFile.c_str());
        _error->Discard();
        return;
    }
    
    pkgTagFile tags = &fileDescriptor;
    pkgTagSection section;
    tags.Step(section);
    
    self.icon = [self urlFromTagSection:&section tag:@"default-icon"];
    self.depiction = [self urlFromTagSection:&section tag:@"depiction"];
    self.descriptionURL = [self urlFromTagSection:&section tag:@"description"];
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
        NSLog(@"No tag for %@", tag);
        return nil;
    } else {
        NSLog(@"tag for section %@: %s",tag, tagValue.c_str());
        return @(tagValue.c_str());
    }
}

- (NSArray *)filesAssociatedWithReleaseIndex:(nonnull debReleaseIndex*)releaseIndex {
    pkgAcquire acquire;
    bool getAllIndexes = true;
    releaseIndex->GetIndexes(&acquire, getAllIndexes);
    
    pkgAcquire::ItemIterator itemIndex = acquire.ItemsBegin();
    NSMutableArray *files = [NSMutableArray new];
    
    for (;itemIndex != acquire.ItemsEnd(); itemIndex += 1) {
        pkgAcquire::Item *item = *itemIndex;
        string descriptionURIString = item->DescURI();
        NSString *descriptionURI = @(descriptionURIString.c_str());
        [files addObject:descriptionURI];
        if (![descriptionURI hasSuffix:@"/Packages.bz2"]) {
            continue;
        }
        
        NSString *noExtension = [descriptionURI stringByDeletingPathExtension];
        [files addObject:noExtension];
        [files addObject:[noExtension stringByAppendingPathExtension:@"gz"]];
        [files addObject:[noExtension stringByAppendingString:@"Index"]];
    }
    return files;
}

@end
