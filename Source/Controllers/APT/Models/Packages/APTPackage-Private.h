//
//  APTPackage-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

@interface APTPackage (Private)

@property (readonly) pkgCache::VerIterator versionIterator;
@property (readonly) pkgCache::PkgIterator packageIterator;
@property (readonly) pkgCache::VerFileIterator fileIterator;

- (instancetype)initWithVersionIterator:(pkgCache::VerIterator)versionIterator;

@end
