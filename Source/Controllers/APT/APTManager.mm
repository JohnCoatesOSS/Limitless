//
//  APTManager.mn
//  Cydia
//
//  Created on 11/18/16.
//

#import "System.h"
#import "APTManager.h"
#import "Apt.h"
#import "Paths.h"

@interface APTManager ()

@property BOOL hasBeenSetup;

@end

@implementation APTManager

+ (instancetype)sharedInstance {
    static APTManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [APTManager new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

// MARK: - Setup

- (void)setup {
    if (self.hasBeenSetup) {
        return;
    }
    self.hasBeenSetup = true;
    
    _assert(pkgInitConfig(*_config));
    
    if ([Device isSimulator]) {
        [self simulatorSetup];
    }
    
    if ([Platform isSandboxed]) {
        [self sandboxSetup];
    }
    
    [self ensureRequiredFilesExist];
    
    [self initiateSystem];
}

- (void)initiateSystem {
    bool result = pkgInitSystem(*_config, _system);
    [self switchOnDebugFlags];
    
    if (!result) {
        _config->Dump();
        GlobalError *error = _GetErrorObj();
        std::string errorMessage;
        error->PopMessage(errorMessage);
        std::cout << "Error: " << errorMessage << std::endl;
    }
    
    _assert(result);
    
    const char *language = getenv("LANG");
    if (language != NULL) {
        _config->Set("APT::Acquire::Translation", language);
    }
    
    int64_t usermem(0);
    size_t size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1) {
        usermem = 0;
    }
    _config->Set("Acquire::http::MaxParallel", usermem >= 384 * 1024 * 1024 ? 16 : 3);
    _config->Set("Dir::Cache", [Paths cacheDirectory].UTF8String);
    _config->Set("Dir::State", [Paths cacheDirectory].UTF8String);
    _config->Set("Dir::State::Lists", [Paths cacheFile:@"lists"].UTF8String);
    
    if ([Device isSimulator]) {
        _config->Set("Dir::Bin::dpkg", "/usr/local/bin/dpkg");
        _config->Set("Dir::Log::Terminal", [Paths cacheFile:@"apt.log"].UTF8String);
    } else {
        _config->Set("Dir::Bin::dpkg", "/Applications/Limitless.app/runAsSuperuser");
        std::string logs("/var/mobile/Library/Logs/Cydia");
        mkdir(logs.c_str(), 0755);
        _config->Set("Dir::Log::Terminal", logs + "/apt.log");
    }
}

- (void)simulatorSetup {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *methodsDirectory = [bundle pathForResource:@"methods" ofType:nil];
    _config->Set("APT::Architecture", "iphoneos-arm");
    _config->Set("Apt::System", "Debian dpkg interface");
    _config->Set("Dir::Etc::trusted", "trusted.gpg");
    _config->Set("Dir::Etc::TrustedParts","trusted.gpg.d");
    _config->Set("Dir::State::status", [Paths dpkgStatus].UTF8String);
    _config->Set("Dir::Bin::methods", methodsDirectory.UTF8String);
    _config->Set("Dir::Bin::gpg", "/usr/local/bin/gpgv");
    _config->Set("Dir::Bin::lzma", "/usr/local/bin/lzma");
    _config->Set("Dir::Bin::bzip2", "/usr/bin/bzip2");
}

- (void)sandboxSetup {
    if ([Platform isSandboxed]) {
        [self switchOnDebugFlags];
        _config->Set("Dir", [Paths applicationLibraryDirectory].UTF8String);
    }
}

- (void)switchOnDebugFlags {
    _config->Set("Debug", "true");
    _config->Set("Debug::Acquire", "true");
    _config->Set("Debug::Acquire::gpgv", "true");
    _config->Set("Debug::pkgPackageManager", "true");
    _config->Set("Debug::GetListOfFilesInDir", "true");
    _config->Set("Debug::pkgAcquire", "true");
    _config->Set("Debug::pkgInitConfig", "true");
}

- (void)ensureRequiredFilesExist {
    mkdir([Paths cacheFile:@"archives"].UTF8String, 0755);
    mkdir([Paths cacheFile:@"archives/partial"].UTF8String, 0755);
    mkdir([Paths cacheFile:@"lists"].UTF8String, 0755);
    mkdir([Paths cacheFile:@"lists/partial"].UTF8String, 0755);
    mkdir([Paths cacheFile:@"periodic"].UTF8String, 0755);
    
    symlink("/var/lib/apt/extended_states", [Paths cacheFile:@"extended_states"].UTF8String);
    
    if (![Platform isSandboxed]) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptDirectory = [Paths etcAptDirectory];
    
    NSString *sourcesDirectory = [aptDirectory stringByAppendingPathComponent:@"sources.list.d"];
    [Paths createDirectoryIfDoesntExist:sourcesDirectory];
    
    NSString *cydiaList = [sourcesDirectory stringByAppendingPathComponent:@"cydia.list"];
    if (![fileManager fileExistsAtPath:cydiaList]) {
        NSLog(@"APT: writing %@", cydiaList);
        [[NSString stringWithFormat:@
          "deb http://apt.saurik.com/ ios/%.2f main\n"
          "deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n"
          "deb http://cydia.zodttd.com/repo/cydia/ stable main\n"
          "deb http://apt.modmyi.com/ stable main\n",
          kCFCoreFoundationVersionNumber] writeToFile:cydiaList atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    // set executable permission on files
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *methods = [bundle pathForResource:@"methods"
                                         ofType:nil];
    
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
    
    NSString *trustedGgpDirectory = [bundle pathForResource:@"Trusted.gpg"
                                                     ofType:nil];
    NSArray *trustedGpgFiles = [fileManager contentsOfDirectoryAtPath:trustedGgpDirectory
                                                                error:&error];
    if (error) {
        NSLog(@"Error reading trustedGPG directory: %@", error);
        assert(0);
    }
    
    NSString *trustedGpgDestinationDirectory = [Paths documentsFile:@"etc/apt/trusted.gpg.d"];
    [Paths createDirectoryIfDoesntExist:trustedGpgDestinationDirectory];
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
    
    if (![fileManager fileExistsAtPath:[Paths dpkgStatus]]) {
        [fileManager createFileAtPath:[Paths dpkgStatus]
                             contents:[NSData data]
                           attributes:nil];
    }
}

@end
