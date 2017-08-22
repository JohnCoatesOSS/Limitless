//
//  APTRecords.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "Apt.h"
#import "APTRecords-Private.h"
#import "APTCacheFile-Private.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTRecords ()

@property pkgRecords *records;

@end

@implementation APTRecords

// MARK: - Init & Dealloc

- (instancetype)initWithCacheFile:(APTCacheFile *)cacheFile {
    self = [super init];

    if (self) {
        pkgCacheFile &cache = *cacheFile.cacheFile;
        _records = new pkgRecords(cache);
    }

    return self;
}

- (void)dealloc {
    delete _records;
}

// MARK: - Private Methods

- (pkgRecords::Parser *)lookUpVersionFileIterator:(pkgCache::VerFileIterator)versionFileIterator {
    return &self.records->Lookup(versionFileIterator);
}

- (pkgRecords::Parser *)lookUpDescriptionFileIterator:(pkgCache::DescFileIterator)descriptionFileIterator {
    return &self.records->Lookup(descriptionFileIterator);
}

@end

APT_SILENCE_DEPRECATIONS_END
