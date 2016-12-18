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
#import "APTSource+APTLib.h"
#import "LMXAPTConfig.h"
#import "APTManager+Files.h"
#import "LMXAPTStatus.hpp"

@interface APTManager ()

@property BOOL hasBeenSetup;
@property LMXAPTConfig *configuration;

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
        _configuration = [LMXAPTConfig new];
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

    [self ensureRequiredFilesExist];

    pkgInitConfig(*_config);

    if ([Device isSimulator]) {
        [self simulatorSetup];
    }

    if ([Platform isSandboxed]) {
        [self sandboxSetup];
    }

    [self initiateSystem];
}

- (void)initiateSystem {
    bool result = pkgInitSystem(*_config, _system);

    if (!result) {
        _config->Dump();
        GlobalError *error = _GetErrorObj();
        std::string errorMessage;
        error->PopMessage(errorMessage);
        std::cout << "Error: " << errorMessage << std::endl;
    }

    const char *language = getenv("LANG");
    if (language != NULL) {
        self.configuration[@"APT::Acquire::Translation"] = @(language);
    }

    int64_t usermem(0);
    size_t size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1) {
        usermem = 0;
    }
    
    int maximumParallelHTTPProcesses;
    if (usermem >= 384 * 1024 * 1024) {
        maximumParallelHTTPProcesses = 16;
    } else {
        maximumParallelHTTPProcesses = 3;
    }
    
    self.configuration[@"Acquire::http::MaxParallel"] = @(maximumParallelHTTPProcesses).stringValue;
    self.configuration[@"Dir::Cache"] = Paths.aptCache;
    self.configuration[@"Dir::State"] = Paths.aptState;
    self.configuration[@"Dir::State::Lists"] = Paths.aptStateLists;

    if ([Device isSimulator]) {
        NSString *logFile = [Paths cacheFile:@"apt.log"];
        self.configuration[@"Dir::Bin::dpkg"] = @"/usr/local/bin/dpkg";
        self.configuration[@"Dir::Log::Terminal"] = logFile;
    } else {
        self.configuration[@"Dir::Bin::dpkg"] = @"/Applications/Limitless.app/runAsSuperuser";
        NSString *logDirectory = @"/var/mobile/Library/Logs/Cydia";
        mkdir(logDirectory.UTF8String, 0755);
        NSString *logFile = [logDirectory stringByAppendingPathComponent:@"apt.log"];
        self.configuration[@"Dir::Log::Terminal"] = logFile;
    }

    if (APTManager.debugMode) {
        _config->Dump();
    }
}
- (void)sandboxSetup {
    if ([Platform isSandboxed]) {
        _debugMode = TRUE;
        [self updateDebugFlags];
        self.configuration[@"Dir"] = Paths.sandboxDocumentsDirectory;
        self.configuration[@"Dir::Etc"] = Paths.aptEtc;
        self.configuration[@"Dir::Etc::TrustedParts"] = @"trusted.gpg.d";
    }
}

- (void)setDirectoryForKey:(NSString *)key directory:(NSString *)directory {
    _config->Set(key.UTF8String, directory.UTF8String);
}


// MARK: - Debug

static BOOL _debugMode = false;

+ (BOOL)debugMode {
    if ([Platform isRelease]) {
        return FALSE;
    }

    return _debugMode;
}

+ (void)setDebugMode:(BOOL)debugMode {
    _debugMode = debugMode;
    [[APTManager sharedInstance] updateDebugFlags];
}

- (void)updateDebugFlags {
    NSString *debugMode;
    if (APTManager.debugMode) {
        debugMode = @"true";
    } else {
        debugMode = @"false";
    }
    self.configuration[@"Debug"] = debugMode;
    self.configuration[@"Debug::Acquire"] = debugMode;
    self.configuration[@"Debug::Acquire::gpgv"] = debugMode;
    self.configuration[@"Debug::pkgPackageManager"] = debugMode;
    self.configuration[@"Debug::GetListOfFilesInDir"] = debugMode;
    self.configuration[@"Debug::pkgAcquire"] = debugMode;
    self.configuration[@"Debug::pkgInitConfig"] = debugMode;
    self.configuration[@"Debug::pkgAcquire::Worker"] = debugMode;
}

// MARK: - Simulator Setup

- (void)simulatorSetup {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *methodsDirectory = [bundle pathForResource:@"methods" ofType:nil];
    self.configuration[@"APT::Architecture"] = @"iphoneos-arm";
    self.configuration[@"Apt::System"] = @"Debian dpkg interface";
    self.configuration[@"Dir::State::status"] = [Paths dpkgStatus];
    self.configuration[@"Dir::Bin::methods"] = methodsDirectory;
    self.configuration[@"Dir::Bin::gpg"] = @"/usr/local/bin/gpgv";
    self.configuration[@"Dir::Bin::lzma"] = @"/usr/local/bin/lzma";
    self.configuration[@"Dir::Bin::bzip2"] = @"/usr/bin/bzip2";

    [self setUpEnviromentForLaunchingMethods];
}

- (void)setUpEnviromentForLaunchingMethods {
    setenv("PATH", "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin", true);
    unsetenv("DYLD_ROOT_PATH");
    unsetenv("DYLD_INSERT_LIBRARIES");
    unsetenv("DYLD_LIBRARY_PATH");
}

// MARK: - Debug

+ (void)clearAPTState {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *aptDirectory = Paths.aptDirectory;
    if (![fileManager fileExistsAtPath:aptDirectory]) {
        return;
    }

    NSLog(@"Clearing APT State");
    [fileManager removeItemAtPath:aptDirectory
                            error:&error];
    if (error) {
        NSLog(@"Error clearing APT State @ %@: %@", aptDirectory, error);
    }
}

@end
