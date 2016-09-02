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
    if ([Device isSimulator]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *urls = [fileManager URLsForDirectory:NSLibraryDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *url = urls[0];
        NSString *path = url.path;
        return path;
    }
    
    return @"/var/mobile/Library/Cydia";
}

+ (NSString *)varLibCydiaDirectory {
    if ([Device isSimulator]) {
        NSString *applicationLibraryDirectory = [self applicationLibraryDirectory];
        NSString *varLibCydiaDirectory = [applicationLibraryDirectory stringByAppendingPathComponent:@"varLibCydia"];
        [self createDirectoryIfDoesntExist:varLibCydiaDirectory];
        return varLibCydiaDirectory;
    }
    
    
    return @"/var/lib/cydia";
}

+ (void)createDirectoryIfDoesntExist:(NSString *)directory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:directory]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:FALSE
                                attributes:nil
                                     error:&error];
        
        if (error) {
            NSLog(@"Failed to create directory at path %@: %@", directory, error);
        }
        
    }
}

+ (NSString *)cacheDirectory {
    if ([Device isSimulator]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *url = urls[0];
        NSString *path = url.path;
        return path;
    }
    
    return @"/var/mobile/Library/Caches/com.saurik.Cydia";
}

+ (NSString *)cacheState {
    return [[self cacheDirectory] stringByAppendingPathComponent:@"CacheState.plist"];
}

+ (NSString *)savedState {
    return [[self cacheDirectory] stringByAppendingPathComponent:@"SavedState.plist"];
}

+ (NSString *)sourcesList {
    return [[self cacheDirectory] stringByAppendingPathComponent:@"sources.list"];
}

@end
