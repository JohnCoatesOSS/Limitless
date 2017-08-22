//
//  APTRecords-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

#import "APTRecords.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTRecords (Private)

@property (readonly) pkgRecords *records;

- (pkgRecords::Parser *)lookUpVersionFileIterator:(pkgCache::VerFileIterator)versionFileIterator;

- (pkgRecords::Parser *)lookUpDescriptionFileIterator:(pkgCache::DescFileIterator)descriptionFileIterator;

@end

APT_SILENCE_DEPRECATIONS_END
