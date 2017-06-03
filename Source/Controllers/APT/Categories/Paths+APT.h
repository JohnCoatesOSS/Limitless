//
//  Paths+APT.h
//  Limitless
//
//  Created on 12/6/16.
//

#import "Paths.h"

@interface Paths (APT)

@property (class, readonly, nonnull) NSString *aptDirectory;

@property (class, readonly, nonnull) NSString *aptState;
@property (class, readonly, nonnull) NSString *aptStateLists;
@property (class, readonly, nonnull) NSString *aptStateListsPartial;

@property (class, readonly, nonnull) NSString *aptCache;
@property (class, readonly, nonnull) NSString *aptCacheArchives;
@property (class, readonly, nonnull) NSString *aptCacheArchivesPartial;

@property (class, readonly, nonnull) NSString *aptEtc;
@property (class, readonly, nonnull) NSString *aptEtcSourceParts;
@property (class, readonly, nonnull) NSString *aptEtcPreferencesParts;
@property (class, readonly, nonnull) NSString *aptEtcTrustedParts;

@property (class, readonly, nonnull) NSString *dpkgStatus;

@end
