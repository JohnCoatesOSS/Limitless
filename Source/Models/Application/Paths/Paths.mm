//
//  Paths.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "Paths.h"

@interface Paths ()

@end

@implementation Paths

+ (NSString *)applicationLibraryDirectory {
    if ([Platform isSandboxed]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *url = urls[0];
        NSString *path = url.path;
        return path;
    }
    
    return @"/var/mobile/Library/Cydia";
}

+ (NSString *)varLibCydiaDirectory {
    if ([Platform isSandboxed]) {
        NSString *applicationLibraryDirectory = [self applicationLibraryDirectory];
        NSString *varLibCydiaDirectory = [applicationLibraryDirectory stringByAppendingPathComponent:@"var/lib/cydia"];
        [self createDirectoryIfDoesntExist:varLibCydiaDirectory];
        return varLibCydiaDirectory;
    }
    
    return @"/var/lib/cydia";
}

+ (NSString *)etcAptDirectory {
    if ([Platform isSandboxed]) {
        NSString *directory = [[self applicationLibraryDirectory] stringByAppendingPathComponent:@"etc/apt"];
        
        [self createDirectoryIfDoesntExist:directory];
        return directory;
        
    }
    return @"/etc/apt";
}

+ (NSString *)cacheDirectory {
    if ([Platform isSandboxed]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *url = urls[0];
        NSString *path = url.path;
        return path;
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia";
}
+ (NSString *)cacheFile:(NSString *)filename {
    return [[self cacheDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)documentsFile:(NSString *)filename {
    return [[self applicationLibraryDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)cacheState {
    return [self cacheFile:@"CacheState.plist"];
}

+ (NSString *)savedState {
    return [self cacheFile:@"SavedState.plist"];
}

+ (NSString *)sourcesList {
    return [self cacheFile:@"sources.list"];
}

+ (NSString *)dpkgStatus {
    if ([Platform isSandboxed]) {
        NSString *applicationLibraryDirectory = [self applicationLibraryDirectory];
        NSString *dpkgDirectory = [applicationLibraryDirectory stringByAppendingPathComponent:@"var/lib/dpkg"];
        [self createDirectoryIfDoesntExist:dpkgDirectory];
        return [dpkgDirectory stringByAppendingPathComponent:@"status"];
    }
    
    return @"/var/lib/dpkg/status";
}

+ (void)createDirectoryIfDoesntExist:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:directory]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        
        if (error) {
            NSLog(@"Failed to create directory at path %@: %@", directory, error);
        }
        
    }
}

@end
