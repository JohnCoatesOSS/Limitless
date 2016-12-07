//
//  Paths+APT.m
//  Limitless
//
//  Created on 12/6/16.
//

#import "Paths+APT.h"
#import "NSString+Paths.h"

@implementation Paths (APT)

+ (NSString *)aptDirectory {
    return [self documentsFile:@"apt/"];
}

+ (NSString *)aptSandboxPath:(NSString *)subpath {
    return [self.aptDirectory subpath:subpath];
}

/// Dir::State
+ (NSString *)aptState {
    return self.aptCache;
}

/// Dir::State::lists
+ (NSString *)aptStateLists {    
    return [self.aptState subpath:@"lists/"];
}

/// Dir::State::lists + partial/
+ (NSString *)aptStateListsPartial {
    return [self.aptStateLists subpath:@"partial/"];
}

/// Dir::Cache
+ (NSString *)aptCache {
    if ([Platform isSandboxed]) {
        return [self aptSandboxPath:@"cache/"];
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia/";
}

// Dir::Cache::Archives
+ (NSString *)aptCacheArchives {
    return [self.aptCache subpath:@"archives/"];
}

+ (NSString *)aptCacheArchivesPartial {
    return [self.aptCacheArchives subpath:@"partial/"];
}

// Dir::Etc
+ (NSString *)aptEtc {
    if ([Platform isSandboxed]) {
        return [self aptSandboxPath:@"etc/"];
    }
    
    return @"/etc/apt/";
}

// Dir::Etc::sourceparts
+ (NSString *)aptEtcSourceParts {
    return [self.aptEtc subpath:@"sources.list.d/"];
}

// Dir::Etc::preferencesparts
+ (NSString *)aptEtcPreferencesParts {
    return [self.aptEtc subpath:@"preferences.d/"];
}

// Dir::Etc::TrustedParts
+ (NSString *)aptEtcTrustedParts {
    return [self.aptEtc subpath:@"trusted.gpg.d/"];
}

+ (NSString *)dpkgStatus {
    if ([Platform isSandboxed]) {
        return [self aptSandboxPath:@"dpkg/status"];
    }
    
    return @"/var/lib/dpkg/status";
}
@end
