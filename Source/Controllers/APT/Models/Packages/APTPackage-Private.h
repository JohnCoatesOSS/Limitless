//
//  APTPackage-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

@interface APTPackage (Private)

@property (readonly) pkgCache::VerIterator versionIterator;
@property (readonly) pkgCache::PkgIterator packageIterator;
@property (readonly) pkgCache::VerFileIterator fileIterator;

- (instancetype)initWithVersionIterator:(pkgCache::VerIterator)versionIterator;

@end
