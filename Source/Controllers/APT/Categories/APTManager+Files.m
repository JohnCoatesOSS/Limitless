//
//  APTManager+Files.m
//  Limitless
//
//  Created on 12/6/16.
//

#import "APTManager+Files.h"
#import "Paths.h"
#import "System.h"

@implementation APTManager (Files)

- (void)ensureRequiredFilesExist {
    [self createDirectories];
    [self setUpSymlinks];
    
    if ([Platform isSandboxed]) {
        [self hydrateSandbox];
    }
}

- (void)createDirectories {
    [Paths createDirectoryIfDoesntExist:Paths.aptState];
    [Paths createDirectoryIfDoesntExist:Paths.aptStateLists];
    [Paths createDirectoryIfDoesntExist:Paths.aptStateListsPartial];
    
    [Paths createDirectoryIfDoesntExist:Paths.aptCache];
    [Paths createDirectoryIfDoesntExist:Paths.aptCacheArchives];
    [Paths createDirectoryIfDoesntExist:Paths.aptCacheArchivesPartial];
    
    [Paths createDirectoryIfDoesntExist:Paths.aptEtc];
    [Paths createDirectoryIfDoesntExist:Paths.aptEtcSourceParts];
    [Paths createDirectoryIfDoesntExist:Paths.aptEtcPreferencesParts];
    [Paths createDirectoryIfDoesntExist:Paths.aptEtcTrustedParts];
}

- (void)setUpSymlinks {
    if ([Platform isSandboxed]) {
        return;
    }
    
    NSString *symlinkTarget = [Paths rootFile:@"var/lib/apt/extended_states"];
    const char *symlinkPath = [Paths.aptCache subpath:@"extended_states"].UTF8String;
    symlink(symlinkTarget.UTF8String, symlinkPath);
}

- (void)hydrateSandbox {
    [self sandboxWriteSourcesList];
    [self sandboxMakeMethodsExecutable];
    [self sandboxCopyTrustedGPGs];
    [self sandboxCreateDpkgStatus];
}

- (void)sandboxWriteSourcesList {
    NSString *sourcesDirectory = Paths.aptEtcSourceParts;
    
    NSString *cydiaList = [sourcesDirectory stringByAppendingPathComponent:@"cydia.list"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cydiaList]) {
        NSLog(@"APT: writing %@", cydiaList);
        [[NSString stringWithFormat:@
          "deb http://apt.saurik.com/ ios/%.2f main\n"
          "deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n"
          "deb http://cydia.zodttd.com/repo/cydia/ stable main\n"
          "deb http://apt.modmyi.com/ stable main\n",
          kCFCoreFoundationVersionNumber] writeToFile:cydiaList atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)sandboxMakeMethodsExecutable {
    NSString *methods = [[NSBundle mainBundle] pathForResource:@"methods" ofType:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *methodsFiles = [fileManager contentsOfDirectoryAtPath:methods error:&error];
    if (error) {
        NSLog(@"Error reading methods directory: %@", error);
        assert(0);
    }
    
    for (NSString *file in methodsFiles) {
        NSString *filePath = [methods stringByAppendingPathComponent:file];
        chmod(filePath.UTF8String, 0777);
    }
}

- (void)sandboxCopyTrustedGPGs {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *trustedGgpDirectory = [[NSBundle mainBundle] pathForResource:@"Trusted.gpg"
                                                                    ofType:nil];
    NSError *error = nil;
    NSArray *trustedGpgFiles = [fileManager contentsOfDirectoryAtPath:trustedGgpDirectory
                                                                error:&error];
    if (error) {
        NSLog(@"Error reading trustedGPG directory: %@", error);
        assert(0);
    }
    
    NSString *trustedGpgDestinationDirectory = Paths.aptEtcTrustedParts;
    
    for (NSString *file in trustedGpgFiles) {
        NSString *destinationPath = [trustedGpgDestinationDirectory
                                     stringByAppendingPathComponent:file];
        if (![fileManager fileExistsAtPath:destinationPath]) {
            NSString *fromPath = [trustedGgpDirectory stringByAppendingPathComponent:file];
            [fileManager copyItemAtPath:fromPath
                                 toPath:destinationPath
                                  error:&error];
            if (error) {
                NSLog(@"Error copying file: %@", error);
                assert(0);
            }
        }
    }
}

- (void)sandboxCreateDpkgStatus {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *statusPath = Paths.dpkgStatus;
    if (![fileManager fileExistsAtPath:statusPath]) {
        NSString *directory = [statusPath stringByDeletingLastPathComponent];
        [Paths createDirectoryIfDoesntExist:directory];
        
        [fileManager createFileAtPath:Paths.dpkgStatus
                             contents:[NSData data]
                           attributes:nil];
    }
}

@end
