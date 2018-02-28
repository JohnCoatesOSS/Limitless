//
//  Paths.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import "Paths.h"
#import "Platform.h"
#import <sys/stat.h>

@interface Paths ()

@end

@implementation Paths

+ (NSURL *)applicationDirectory {
    return [NSURL URLWithString:@"/Applications/Limitless.app"];
}

+ (NSURL *)applicationBinary {
    return [[self applicationDirectory] URLByAppendingPathComponent:@"Limitless"];
}

+ (NSString *)sandboxDocumentsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory
                                        inDomains:NSUserDomainMask];
    NSURL *url = urls[0];
    NSString *path = url.path;
    return path;
}

+ (NSString *)rootDirectory {
    if ([Platform isSandboxed]) {
        NSString *directory = [self documentsFile:@"root/"];
        [self createDirectoryIfDoesntExist:directory];
        return directory;
    }
    
    return @"/";
    
}

+ (NSString *)applicationLibraryDirectory {
    if ([Platform isSandboxed]) {
        return [self sandboxDocumentsDirectory];
    }
    
    return @"/var/mobile/Library/Limitless";
}

+ (NSString *)varLibCydiaDirectory {
    if ([Platform isSandboxed]) {
        NSString *varLibCydiaDirectory = [self rootFile:@"var/lib/cydia"];
        [self createDirectoryIfDoesntExist:varLibCydiaDirectory];
        return varLibCydiaDirectory;
    }
    
    return @"/var/lib/cydia";
}

+ (NSString *)etcAptDirectory {
    if ([Platform isSandboxed]) {
        NSString *directory = [self rootFile:@"etc/apt"];
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
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia/";
}

+ (NSString *)stateDirectory {
    if ([Platform isSandboxed]) {
        NSString *directory = [self cacheFile:@"APTState/"];
        [self createDirectoryIfDoesntExist:directory];
        return directory;
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia/";
}


+ (NSString *)cacheFile:(NSString *)filename {
    return [[self cacheDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)documentsFile:(NSString *)filename {
    return [[self applicationLibraryDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)rootFile:(NSString *)filename {
    return [[self rootDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)aptFile:(NSString *)filename {
    return [[self etcAptDirectory] stringByAppendingPathComponent:filename];
}

+ (NSString *)stateFile:(NSString *)filename {
    return [[self etcAptDirectory] stringByAppendingPathComponent:filename];
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
    
    chmod(directory.UTF8String, 0755);
}

@end
