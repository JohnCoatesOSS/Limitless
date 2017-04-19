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
#import "LMXAPTSource+APTLib.h"
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
        _config->Set("APT::Acquire::Translation", language);
    }
    
    int64_t usermem(0);
    size_t size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1) {
        usermem = 0;
    }
    _config->Set("Acquire::http::MaxParallel", usermem >= 384 * 1024 * 1024 ? 16 : 3);
    
    self.configuration[@"Dir::State"] = Paths.aptState;
    self.configuration[@"Dir::Cache"] = Paths.aptCache;
    self.configuration[@"Dir::Etc::TrustedParts"] = @"trusted.gpg.d";
    
    if ([Device isSimulator]) {
        NSString *logFile = [Paths cacheFile:@"apt.log"];
        _config->Set("Dir::Bin::dpkg", "/usr/local/bin/dpkg");
        _config->Set("Dir::Log::Terminal", logFile.UTF8String);
    } else {
        _config->Set("Dir::Bin::dpkg", "/Applications/Limitless.app/runAsSuperuser");
        std::string logs("/var/mobile/Library/Logs/Cydia");
        mkdir(logs.c_str(), 0755);
        _config->Set("Dir::Log::Terminal", logs + "/apt.log");
    }
    
    _config->Dump();
}

- (void)simulatorSetup {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *methodsDirectory = [bundle pathForResource:@"methods" ofType:nil];
    _config->Set("APT::Architecture", "iphoneos-arm");
    _config->Set("Apt::System", "Debian dpkg interface");
    _config->Set("Dir::State::status", [Paths dpkgStatus].UTF8String);
    _config->Set("Dir::Bin::methods", methodsDirectory.UTF8String);
    _config->Set("Dir::Bin::gpg", "/usr/local/bin/gpgv");
    _config->Set("Dir::Bin::lzma", "/usr/local/bin/lzma");
    _config->Set("Dir::Bin::bzip2", "/usr/bin/bzip2");
}

- (void)sandboxSetup {
    if ([Platform isSandboxed]) {
        [self switchOnDebugFlags];
        self.configuration[@"Dir"] = Paths.sandboxDocumentsDirectory;
        self.configuration[@"Dir::Etc"] = Paths.aptEtc;
    }
}

- (void)setDirectoryForKey:(NSString *)key directory:(NSString *)directory {
    _config->Set(key.UTF8String, directory.UTF8String);
}

- (void)switchOnDebugFlags {
    _config->Set("Debug", "true");
    _config->Set("Debug::Acquire", "true");
    _config->Set("Debug::Acquire::gpgv", "true");
    _config->Set("Debug::pkgPackageManager", "true");
    _config->Set("Debug::GetListOfFilesInDir", "true");
    _config->Set("Debug::pkgAcquire", "true");
    _config->Set("Debug::pkgInitConfig", "true");
    _config->Set("Debug::pkgAcquire::Worker", "true");
}

// MARK: - Updating

- (BOOL)performUpdate {
    OpProgress progress;
    pkgCacheFile cache;
    bool cacheOpened = cache.Open(progress, false);
    if (!cacheOpened) {
        NSLog(@"error opening cache: %@", self.popLatestErrors);
        return FALSE;
    }
    
    LMXAptStatus *status = new LMXAptStatus();
    pkgAcquire *fetcher = new pkgAcquire(status);
    pkgDepCache::Policy *policy = new pkgDepCache::Policy();
    pkgRecords *records = new pkgRecords(cache);
    pkgProblemResolver *resolver_ = new pkgProblemResolver(cache);
    
    pkgPackageManager *manager = _system->CreatePM(cache);
    
    pkgSourceList sourceList;
    if (!sourceList.ReadMainList()) {
        NSArray *latestErrors = self.popLatestErrors;
        NSLog(@"error: %@", latestErrors);
        return FALSE;
    }
    
    manager->GetArchives(fetcher, &sourceList, records);
    
    bool updated = ListUpdate(*status, sourceList);
    NSLog(@"updated: %d", updated);
    
    int PulseInterval = 500000;
    if (fetcher->Run(PulseInterval) != pkgAcquire::Continue) {
        
        NSLog(@"fetcher errors: %@", [self popLatestErrors]);
        return FALSE;
    }
    
    bool failed = false;
    for (pkgAcquire::ItemIterator item = fetcher->ItemsBegin(); item != fetcher->ItemsEnd(); item++) {
        if ((*item)->Status == pkgAcquire::Item::StatDone && (*item)->Complete)
            continue;
        if ((*item)->Status == pkgAcquire::Item::StatIdle)
            continue;
        
        std::string uri = (*item)->DescURI();
        std::string error = (*item)->ErrorText;
        
        NSLog(@"pAf:%s:%s\n", uri.c_str(), error.c_str());
        failed = true;
        
        NSString *errorString = @(error.c_str());
        NSLog(@"Acquire error: %@", errorString);
        
//        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:error.c_str()] ofType:kCydiaProgressEventTypeError]);
//        [delegate_ addProgressEventOnMainThread:event forTask:title];
    }
    
    
    return updated;
}

// MARK: - Properties

- (NSArray <LMXAPTSource *> *)readSourcesWithError:(NSError **)error {
    pkgSourceList sourceList;
    if (!sourceList.ReadMainList()) {
        NSArray *latestErrors = self.popLatestErrors;
        NSLog(@"encountered error reading sources list: %@", latestErrors);
        
        NSString *localizedError = [NSString stringWithFormat:@"APT Errors: %@", latestErrors];
        *error = [NSError limitlessErrorWithMessage:localizedError];
        return nil;
    }
    
    NSMutableArray *sources = [NSMutableArray new];
    pkgSourceList::const_iterator sourceMetaIndex = sourceList.begin();
    while (sourceMetaIndex != sourceList.end()) {
        LMXAPTSource *aptSource = [[LMXAPTSource alloc] initWithMetaIndex:*sourceMetaIndex];
        [sources addObject:aptSource];
        sourceMetaIndex += 1;
    }
    
    return sources;
}


- (NSArray *)popLatestErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    while (!_error->empty()) {
        std::string message;
        bool isFatal = _error->PopMessage(message);
        if (isFatal) {
//            [NSException raise:@"APTError"
//                        format:@"Fatal APT error: %s", message.c_str()];
        }
        NSString *error = @(message.c_str());
        [errors addObject:error];
    }
    
    return errors;
}

@end
