//
//  APTPackage.m
//  Limitless
//
//  Created on 12/19/16.
//

#import "Apt.h"
#import "APTPackage-Private.h"

@interface APTPackage ()

@property pkgCache::VerIterator versionIterator;
@property pkgCache::PkgIterator packageIterator;
@property pkgCache::VerFileIterator fileIterator;

@end

@implementation APTPackage

// MARK: - Init & Dealloc

- (instancetype)initWithVersionIterator:(pkgCache::VerIterator)versionIterator {
    self = [super init];

    if (self) {
        _versionIterator = versionIterator;
        _packageIterator = pkgCache::PkgIterator(versionIterator.ParentPkg());
        _fileIterator = _versionIterator.FileList();
    }

    return self;
}

// MARK: -

@end
