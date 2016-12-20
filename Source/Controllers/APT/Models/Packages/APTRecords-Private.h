//
//  APTRecords-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTRecords.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTRecords (Private)

@property (readonly) pkgRecords *records;

- (pkgRecords::Parser *)lookUpVersionFileIterator:(pkgCache::VerFileIterator)versionFileIterator;

- (pkgRecords::Parser *)lookUpDescriptionFileIterator:(pkgCache::DescFileIterator)descriptionFileIterator;

@end

APT_SILENCE_DEPRECATIONS_END
