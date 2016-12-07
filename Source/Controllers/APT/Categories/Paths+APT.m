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
    if ([Platform isSandboxed]) {
        return [self.aptState subpath:@"lists/"];
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia/lists/";
}

/// Dir::State::lists + partial/
+ (NSString *)aptStateListsPartial {
    if ([Platform isSandboxed]) {
        return [self.aptStateLists subpath:@"partial/"];
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia/lists/partial/";
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
    if ([Platform isSandboxed]) {
        return [self.aptCache subpath:@"archives/"];
    }
    
    return @"/var/cache/apt/archives/";
}

+ (NSString *)aptCacheArchivesPartial {
    if ([Platform isSandboxed]) {
        return [self.aptCacheArchives subpath:@"partial/"];
    }
    
    return @"/var/cache/apt/archives/partial/";
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
    if ([Platform isSandboxed]) {
        return [self.aptEtc subpath:@"sources.list.d/"];
    }
    
    return @"/etc/apt/sources.list.d/";
}

// Dir::Etc::preferencesparts
+ (NSString *)aptEtcPreferencesParts {
    if ([Platform isSandboxed]) {
        return [self.aptEtc subpath:@"preferences.d/"];
    }
    
    return @"/etc/apt/preferences.d/";
}

// Dir::Etc::TrustedParts
+ (NSString *)aptEtcTrustedParts {
    if ([Platform isSandboxed]) {
        return [self.aptEtc subpath:@"trusted.gpg.d/"];
    }
    
    return @"/etc/apt/trusted.gpg.d/";
}

+ (NSString *)dpkgStatus {
    if ([Platform isSandboxed]) {
        return [self aptSandboxPath:@"dpkg/status"];
    }
    
    return @"/var/lib/dpkg/status";
}
@end
