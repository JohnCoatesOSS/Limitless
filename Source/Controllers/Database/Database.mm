//
//  Database.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "Database.h"
#import "Standard.h"
#import "Defines.h"
#import "CytoreHelpers.h"
#import "Profiling.hpp"
#import "Source.h"
#import "Package.h"
#import "CFArray+Sort.h"
#import "Logging.hpp"
#import "Paths.h"
#import "APTCacheFile+Legacy.h"
#import "APTDownloadScheduler-Private.h"
#import "APTRecords-Private.h"
#import "APTSource-Private.h"
#import "APTSourceList-Private.h"

@implementation Database

+ (Database *) sharedInstance {
    static _H<Database> instance;
    if (instance == nil) {
        instance = [[Database new] autorelease];
    }
    return instance;
}

- (unsigned) era {
    return era_;
}

- (void) releasePackages {
    CFArrayApplyFunction(packages_,
                         CFRangeMake(0, CFArrayGetCount(packages_)),
                         reinterpret_cast<CFArrayApplierFunction>(&CFRelease), NULL);
    CFArrayRemoveAllValues(packages_);
}

- (void) dealloc {
    // XXX: actually implement this thing
    _assert(false);
    [self releasePackages];
    NSRecycleZone(zone_);
    [super dealloc];
}

- (void) _readCydia:(NSNumber *)fd {
    FILE *file = fdopen([fd intValue], "r");
    char line[1024];
    
    static RegEx finish_r("finish:([^:]*)");
    
    while (fgets(line, sizeof(line), file)) {
        NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
        
        size_t size = strlen(line);
        lprintf("C:%s\n", line);
        
        if (finish_r(line, size)) {
            NSString *finish = finish_r[1];
            int index = [Finishes_ indexOfObject:finish];
            if (index != INT_MAX && index > Finish_)
                Finish_ = index;
        }
        
        [pool release];
    }
    
    _assume(false);
}

- (void) _readStatus:(NSNumber *)fd {
    FILE *file = fdopen([fd intValue], "r");
    char line[1024];
    
    static RegEx conffile_r("status: [^ ]* : conffile-prompt : (.*?) *");
    static RegEx pmstatus_r("([^:]*):([^:]*):([^:]*):(.*)");
    
    while (fgets(line, sizeof(line), file)) {
        NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
        
        size_t size = strlen(line);
        lprintf("S:%s\n", line);
        
        if (conffile_r(line, size)) {
            // status: /line : conffile-prompt : '/fail' '/fail.dpkg-new' 1 1
            [delegate_ performSelectorOnMainThread:@selector(setConfigurationData:) withObject:conffile_r[1] waitUntilDone:YES];
        } else if (strncmp(line, "status: ", 8) == 0) {
            // status: <package>: {unpacked,half-configured,installed}
            CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:(line + 8)] ofType:kCydiaProgressEventTypeStatus]);
            [progress_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
        } else if (strncmp(line, "processing: ", 12) == 0) {
            // processing: configure: config-test
            CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:(line + 12)] ofType:kCydiaProgressEventTypeStatus]);
            [progress_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
        } else if (pmstatus_r(line, size)) {
            std::string type([pmstatus_r[1] UTF8String]);
            
            NSString *package = pmstatus_r[2];
            if ([package isEqualToString:@"dpkg-exec"])
                package = nil;
            
            float percent([pmstatus_r[3] floatValue]);
            [progress_ performSelectorOnMainThread:@selector(setProgressPercent:) withObject:[NSNumber numberWithFloat:(percent / 100)] waitUntilDone:YES];
            
            NSString *string = pmstatus_r[4];
            
            if (type == "pmerror") {
                CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:string ofType:kCydiaProgressEventTypeError forPackage:package]);
                [progress_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
            } else if (type == "pmstatus") {
                CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:string ofType:kCydiaProgressEventTypeStatus forPackage:package]);
                [progress_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
            } else if (type == "pmconffile")
                [delegate_ performSelectorOnMainThread:@selector(setConfigurationData:) withObject:string waitUntilDone:YES];
            else
                lprintf("E:unknown pmstatus\n");
        } else
            lprintf("E:unknown status\n");
        
        [pool release];
    }
    
    _assume(false);
}

- (void) _readOutput:(NSNumber *)fd {
    FILE *file = fdopen([fd intValue], "r");
    char line[1024];
    
    while (fgets(line, sizeof(line), file)) {
        NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
        
        lprintf("O:%s\n", line);
        
        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:line] ofType:kCydiaProgressEventTypeInformation]);
        [progress_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
        
        [pool release];
    }
    
    _assume(false);
}

- (FILE *) input {
    return input_;
}

- (Package *) packageWithName:(NSString *)name {
    return [self.cacheFile packageWithName:name database:self];
}

- (id) init {
    if ((self = [super init]) != nil) {
        lock_ = NULL;
        status_ = new CydiaStatus();
        
        zone_ = NSCreateZone(1024 * 1024, 256 * 1024, NO);
        
        size_t capacity(MetaFile_->active_);
        if (capacity == 0)
            capacity = 16384;
        else
            capacity += 1024;
        
        packages_ = CFArrayCreateMutable(kCFAllocatorDefault, capacity, NULL);
        sourceList_ = [NSMutableArray arrayWithCapacity:16];
        
        int fds[2];
        
        _assert(pipe(fds) != -1);
        cydiafd_ = fds[1];
        
        _config->Set("APT::Keep-Fds::", cydiafd_);
        setenv("CYDIA", [[[[NSNumber numberWithInt:cydiafd_] stringValue] stringByAppendingString:@" 1"] UTF8String], _not(int));
        
        [NSThread
         detachNewThreadSelector:@selector(_readCydia:)
         toTarget:self
         withObject:[NSNumber numberWithInt:fds[0]]
         ];
        
        _assert(pipe(fds) != -1);
        statusfd_ = fds[1];
        
        [NSThread
         detachNewThreadSelector:@selector(_readStatus:)
         toTarget:self
         withObject:[NSNumber numberWithInt:fds[0]]
         ];
        
        _assert(pipe(fds) != -1);
        _assert(dup2(fds[0], 0) != -1);
        _assert(close(fds[0]) != -1);
        
        input_ = fdopen(fds[1], "a");
        
        _assert(pipe(fds) != -1);
        _assert(dup2(fds[1], 1) != -1);
        _assert(close(fds[1]) != -1);
        
        [NSThread
         detachNewThreadSelector:@selector(_readOutput:)
         toTarget:self
         withObject:[NSNumber numberWithInt:fds[0]]
         ];
    } return self;
}

- (NSArray *) packages {
    return (NSArray *) packages_;
}

- (NSArray *) sources {
    return sourceList_;
}

- (Source *) sourceWithKey:(NSString *)key {
    for (Source *source in [self sources]) {
        if ([[source key] isEqualToString:key])
            return source;
    } return nil;
}

- (bool) popErrorWithTitle:(NSString *)title {
    bool fatal(false);
    
    while (!_error->empty()) {
        std::string error;
        bool warning(!_error->PopMessage(error));
        if (!warning)
            fatal = true;
        
        for (;;) {
            size_t size(error.size());
            if (size == 0 || error[size - 1] != '\n')
                break;
            error.resize(size - 1);
        }
        
        lprintf("%c:[%s]\n", warning ? 'W' : 'E', error.c_str());
        
        static RegEx no_pubkey("GPG error:.* NO_PUBKEY .*");
        if (warning && no_pubkey(error.c_str()))
            continue;
        
        [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:error.c_str()] ofType:(warning ? kCydiaProgressEventTypeWarning : kCydiaProgressEventTypeError)] forTask:title];
    }
    
    return fatal;
}

- (bool) popErrorWithTitle:(NSString *)title forOperation:(bool)success {
    return [self popErrorWithTitle:title] || !success;
}

- (void) reloadDataWithInvocation:(NSInvocation *)invocation {
    @synchronized (self) {
        ++era_;
        
        [self releasePackages];
        
        sourceMap_.clear();
        [sourceList_ removeAllObjects];
        
        [APTErrorController popErrors];
        
        self.sourceListController = nil;
        self.packageManager = nil;
        if (lock_) {
            delete lock_;
        }
        lock_ = NULL;
        self.downloadScheduler = nil;
        self.packageRecords = nil;
        self.problemResolver = nil;
        self.policy = nil;
        self.cacheFile = nil;
        
        pool_.~CYPool();
        new (&pool_) CYPool();
        
        NSRecycleZone(zone_);
        zone_ = NSCreateZone(1024 * 1024, 256 * 1024, NO);
        
        int chk(creat("/tmp/cydia.chk", 0644));
        if (chk != -1)
            close(chk);
        
        if (invocation != nil)
            [invocation invoke];
        
        NSString *title(UCLocalize("DATABASE"));
        
        self.sourceListController = [[APTSourceList alloc] initWithMainList];
        if (!self.sourceListController) {
            [self popErrorWithTitle:title];
            return;
        }
        
        for (APTSource *source in self.sourceListController.sources) {
            Source *legacySource = [[Source alloc] initWithMetaIndex:source.metaIndex
                                                        forDatabase:self
                                                             inPool:&pool_];
            [sourceList_ addObject:[legacySource autorelease]];
        }
        
        _trace();
        OpProgress progress;
        NSError *error = nil;
    open:
        delock_ = GetStatusDate();
        _profile(reloadDataWithInvocation$pkgCacheFile)
        
        self.cacheFile = [[APTCacheFile alloc] initWithError:&error];
        
        _end
        if (!self.cacheFile) {
            NSLog(@"cacheFile open failed: %@", error);
            NSString *errorType;
            if (error.code == APTErrorWarning) {
                errorType = kCydiaProgressEventTypeWarning;
            } else {
                errorType = kCydiaProgressEventTypeError;
            }
            CydiaProgressEvent *event = [CydiaProgressEvent eventWithMessage:error.localizedDescription
                                          ofType:errorType];
            
            [delegate_ addProgressEventOnMainThread:event forTask:title];
            
            SEL repair = NULL;
            if ([error.localizedDescription isEqualToString:@"dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem. "]) {
                repair = @selector(configure);
            }
            if (repair != NULL) {
                [delegate_ repairWithSelector:repair];
                goto open;
            }
            
            return;
        }
        _trace();
        
        unlink("/tmp/cydia.chk");
        
        now_ = [[NSDate date] timeIntervalSince1970];
        
        self.policy = [APTDependencyCachePolicy new];
        pkgCacheFile &cache = *self.cacheFile.cacheFile;
        self.packageRecords = [[APTRecords alloc] initWithCacheFile:self.cacheFile];
        self.problemResolver = [[APTPackageProblemResolver alloc] initWithCacheFile:self.cacheFile];
        self.downloadScheduler = [[APTDownloadScheduler alloc] initWithStatusDelegate:status_];
        lock_ = NULL;
        
        APTCacheFile *cacheFile = self.cacheFile;
        
        if (cacheFile.pendingDeletions != 0 || cacheFile.pendingInstalls != 0) {
            [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:UCLocalize("COUNTS_NONZERO_EX") ofType:kCydiaProgressEventTypeError] forTask:title];
            return;
        }
        
        _profile(reloadDataWithInvocation$pkgApplyStatus)
        if ([self popErrorWithTitle:title forOperation:pkgApplyStatus(cache)])
            return;
        _end
        
        if (cacheFile.brokenPackages != 0) {
            _profile(pkgApplyStatus$pkgFixBroken)
            if ([self popErrorWithTitle:title forOperation:pkgFixBroken(cache)])
                return;
            _end
            
            if (cacheFile.brokenPackages != 0) {
                [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:UCLocalize("STILL_BROKEN_EX") ofType:kCydiaProgressEventTypeError] forTask:title];
                return;
            }
            
            _profile(pkgApplyStatus$pkgMinimizeUpgrade)
            if ([self popErrorWithTitle:title forOperation:pkgMinimizeUpgrade(cache)])
                return;
            _end
        }
        
        for (Source *object in (id) sourceList_) {
            metaIndex *source = object.metaIndex;
            std::vector<pkgIndexFile *> *indices = source->GetIndexFiles();
            for (std::vector<pkgIndexFile *>::const_iterator index = indices->begin(); index != indices->end(); ++index)
                // XXX: this could be more intelligent
                if (dynamic_cast<debPackagesIndex *>(*index) != NULL) {
                    pkgCache::PkgFileIterator cached((*index)->FindInCache(cache));
                    if (!cached.end())
                        sourceMap_[cached->ID] = object;
                }
        }
        
        {
            /*std::vector<Package *> packages;
             packages.reserve(std::max(10000U, [packages_ count] + 1000));
             packages_ = nil;*/
            
            _profile(reloadDataWithInvocation$packageWithIterator)
            for (pkgCache::PkgIterator iterator = cache->PkgBegin(); !iterator.end(); ++iterator)
                if (Package *package = [Package packageWithIterator:iterator withZone:zone_ inPool:&pool_ database:self])
                    //packages.push_back(package);
                    CFArrayAppendValue(packages_, CFRetain(package));
            _end
            
            
            /*if (packages.empty())
             packages_ = [[NSArray alloc] init];
             else
             packages_ = [[NSArray alloc] initWithObjects:&packages.front() count:packages.size()];
             _trace();*/
            
            _profile(reloadDataWithInvocation$radix$8)
            [(NSMutableArray *) packages_ radixSortUsingFunction:reinterpret_cast<MenesRadixSortFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(8)];
            _end
            
            _profile(reloadDataWithInvocation$radix$4)
            [(NSMutableArray *) packages_ radixSortUsingFunction:reinterpret_cast<MenesRadixSortFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(4)];
            _end
            
            _profile(reloadDataWithInvocation$radix$0)
            [(NSMutableArray *) packages_ radixSortUsingFunction:reinterpret_cast<MenesRadixSortFunction>(&PackagePrefixRadix) withContext:reinterpret_cast<void *>(0)];
            _end
            
            _profile(reloadDataWithInvocation$insertion)
            CFArrayInsertionSortValues(packages_, CFRangeMake(0, CFArrayGetCount(packages_)), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare), NULL);
            _end
            
            /*_profile(reloadDataWithInvocation$CFQSortArray)
             CFQSortArray(&packages.front(), packages.size(), sizeof(packages.front()), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare_), NULL);
             _end*/
            
            /*_profile(reloadDataWithInvocation$stdsort)
             std::sort(packages.begin(), packages.end(), PackageNameOrdering());
             _end*/
            
            /*_profile(reloadDataWithInvocation$CFArraySortValues)
             CFArraySortValues((CFMutableArrayRef) packages_, CFRangeMake(0, [packages_ count]), reinterpret_cast<CFComparatorFunction>(&PackageNameCompare), NULL);
             _end*/
            
            /*_profile(reloadDataWithInvocation$sortUsingFunction)
             [packages_ sortUsingFunction:reinterpret_cast<NSComparisonResult (*)(id, id, void *)>(&PackageNameCompare) context:NULL];
             _end*/
            
            
            size_t count(CFArrayGetCount(packages_));
            MetaFile_->active_ = count;
            for (size_t index(0); index != count; ++index)
                [(Package *) CFArrayGetValueAtIndex(packages_, index) setIndex:index];
        }
    } }

- (void) clear {
    @synchronized (self) {
        self.problemResolver = nil;
        pkgCacheFile &cache = *self.cacheFile.cacheFile;
        self.problemResolver = [[APTPackageProblemResolver alloc] initWithCacheFile:self.cacheFile];
        
        for (pkgCache::PkgIterator iterator(cache->PkgBegin()); !iterator.end(); ++iterator)
            if (!cache[iterator].Keep())
                cache->MarkKeep(iterator, false);
            else if ((cache[iterator].iFlags & pkgDepCache::ReInstall) != 0)
                cache->SetReInstall(iterator, false);
    } }

- (void) configure {
    _trace();
    [LMXLaunchProcess launchProcessAtPath:@"/Applications/Limitless.app/runAsSuperuser"
                            withArguments:@"--configure", @"-a", @"--status-fd", @(statusfd_), nil];
    _trace();
}

- (bool) clean {
    @synchronized (self) {
        // XXX: I don't remember this condition
        if (lock_ != NULL)
            return false;
        
        FileFd Lock;
        Lock.Fd(GetLock(_config->FindDir("Dir::Cache::Archives") + "lock"));
        
        NSString *title(UCLocalize("CLEAN_ARCHIVES"));
        
        if ([self popErrorWithTitle:title])
            return false;
        
        string archivesPath = _config->FindDir("Dir::Cache::Archives");
        NSString *archivesDirectory = @(archivesPath.c_str());
        
        [self.downloadScheduler
         eraseFilesNotInOperationInDirectory:archivesDirectory];
        
        CydiaLogCleaner cleaner;
        pkgCacheFile &cache = *self.cacheFile.cacheFile;
        if ([self popErrorWithTitle:title forOperation:cleaner.Go(_config->FindDir("Dir::Cache::Archives") + "partial/", cache)])
            return false;
        
        return true;
    } }

- (bool) prepare {
    [self.downloadScheduler terminate];
    
    APTRecords *packageRecords = [[APTRecords alloc] initWithCacheFile:self.cacheFile];
    
    lock_ = new FileFd();
    lock_->Fd(GetLock(_config->FindDir("Dir::Cache::Archives") + "lock"));
    
    NSString *title(UCLocalize("PREPARE_ARCHIVES"));
    
    if ([self popErrorWithTitle:title])
        return false;
    
    APTSourceList *sourceList = [[APTSourceList alloc] initWithMainList];
    if (!sourceList) {
        [self popErrorWithTitle:title];
        return false;
    }
    
    self.packageManager = [[APTPackageManager alloc] initWithCacheFile:self.cacheFile];
    
    BOOL queuedSuccessfully = [self.packageManager queueArchivesForDownloadWithScheduler:self.downloadScheduler
                                                                              sourceList:sourceList
                                                                          packageRecords:packageRecords];
    if ([self popErrorWithTitle:title forOperation:queuedSuccessfully])
        return false;
    
    return true;
}

- (void) perform {
    bool substrate(RestartSubstrate_);
    RestartSubstrate_ = false;
    
    NSString *title(UCLocalize("PERFORM_SELECTIONS"));
    
    NSMutableArray *before = [NSMutableArray arrayWithCapacity:16]; {
        APTSourceList *sourceList = [[APTSourceList alloc] initWithMainList];
        if (!sourceList) {
            [self popErrorWithTitle:title];
            return;
        }
        for (APTSource *source in sourceList.sources) {
            [before addObject:source.uri.absoluteString];
        }
    }
    
    [delegate_ performSelectorOnMainThread:@selector(retainNetworkActivityIndicator)
                                withObject:nil waitUntilDone:YES];
    
    APTDownloadResult downloadResult = [self.downloadScheduler
                                                    runWithDelegateInterval:PulseInterval_];
    if (downloadResult != APTDownloadResultSuccess) {
        [self popErrorWithTitle:title];
        return;
    }
    
    BOOL failed = FALSE;
    
    // Report any errors
    for (APTDownloadItem *item in self.downloadScheduler.items) {
        APTDownloadState state = item.state;
        if (state == APTDownloadStateDone && item.finished) {
            continue;
        }
        else if (state == APTDownloadStateIdle) {
            continue;
        }
        
        NSURL *url = item.url;
        NSString *errorMessage = item.errorMessage;
        
        NSLog(@"Downloading item %@ encountered error: %@", url, errorMessage);
        failed = TRUE;
        
        CydiaProgressEvent *event;
        event = [CydiaProgressEvent eventWithMessage:errorMessage
                                              ofType:kCydiaProgressEventTypeError];
        [delegate_ addProgressEventOnMainThread:event forTask:title];
    }
        
    [delegate_ performSelectorOnMainThread:@selector(releaseNetworkActivityIndicator)
                                withObject:nil waitUntilDone:YES];
    
    if (failed) {
        _trace();
        return;
    }
    
    if (substrate)
        RestartSubstrate_ = true;
    
    if (![delock_ isEqual:GetStatusDate()]) {
        [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:UCLocalize("DPKG_LOCKED") ofType:kCydiaProgressEventTypeError] forTask:title];
        return;
    }
    
    delock_ = nil;
    
    APTInstallResult result = [self.packageManager performInstallationWithOutputToFileDescriptor:statusfd_];
    
    NSString *oextended(@"/var/lib/apt/extended_states");
    NSString *nextended(Cache("extended_states"));
    
    struct stat info;
    if (stat([nextended UTF8String], &info) != -1 && (info.st_mode & S_IFMT) == S_IFREG) {
        if (![Device isSimulator]) {
            [LMXLaunchProcess launchProcessAtPath:@"/Applications/Limitless.app/runAsSuperuser"
                                    withArguments:@"/bin/cp", @"--remove-destination", nextended, oextended,  nil];
        }
    }
    
    unlink([nextended UTF8String]);
    symlink([oextended UTF8String], [nextended UTF8String]);
    
    if ([self popErrorWithTitle:title])
        return;
    
    if (result == APTInstallResultFailed) {
        _trace();
        return;
    }
    
    if (result != APTInstallResultCompleted) {
        _trace();
        return;
    }
    
    NSMutableArray *after = [NSMutableArray arrayWithCapacity:16];
    APTSourceList *sourceList = [[APTSourceList alloc] initWithMainList];
    if (!sourceList) {
        [self popErrorWithTitle:title];
        return;
    }
    
    for (APTSource *source in sourceList.sources) {
        [after addObject:source.uri.absoluteString];
    }
    
    BOOL sourceListHasChanged = ![before isEqualToArray:after];
    if (sourceListHasChanged) {
        [self update];
    }
}

- (bool) delocked {
    return ![delock_ isEqual:GetStatusDate()];
}

- (bool) upgrade {
    NSString *title(UCLocalize("UPGRADE"));
    pkgCacheFile &cache = *self.cacheFile.cacheFile;
    if ([self popErrorWithTitle:title forOperation:pkgDistUpgrade(cache)])
        return false;
    return true;
}

- (void) update {
    [self updateWithStatus:*status_];
}

- (void) updateWithStatus:(CancelStatus &)status {
    NSString *title(UCLocalize("REFRESHING_DATA"));
    
    APTSourceList *sourceList = [[APTSourceList alloc] initWithMainList];
    if (!sourceList) {
        [self popErrorWithTitle:title];
        return;
    }
    
    FileFd lock;
    lock.Fd(GetLock(_config->FindDir("Dir::State::Lists") + "lock"));
    if ([self popErrorWithTitle:title])
        return;
    
    [delegate_
     performSelectorOnMainThread:@selector(retainNetworkActivityIndicator)
     withObject:nil waitUntilDone:YES];    
    
    BOOL success = [sourceList updateWithStatusDelegate:status];
    if (status.WasCancelled())
        _error->Discard();
    else {
        [self popErrorWithTitle:title forOperation:success];
        
        NSString *cacheStatePath = [Paths.aptState subpath:@"CacheState.plist"];
        [[NSDictionary dictionaryWithObjectsAndKeys:
          [NSDate date], @"LastUpdate",
          nil] writeToFile:cacheStatePath atomically:YES];
    }
    
    [delegate_ performSelectorOnMainThread:@selector(releaseNetworkActivityIndicator)
                                withObject:nil waitUntilDone:YES];
}

- (void) setDelegate:(NSObject<DatabaseDelegate> *)delegate {
    delegate_ = delegate;
}

- (void) setProgressDelegate:(NSObject<ProgressDelegate> *)delegate {
    progress_ = delegate;
    status_->setDelegate(delegate);
}

- (NSObject<ProgressDelegate> *) progressDelegate {
    return progress_;
}

- (Source *) getSource:(pkgCache::PkgFileIterator)file {
    SourceMap::const_iterator i(sourceMap_.find(file->ID));
    return i == sourceMap_.end() ? nil : i->second;
}

- (void) setFetch:(bool)fetch forURI:(const char *)uri {
    for (Source *source in (id) sourceList_)
        [source setFetch:fetch forURI:uri];
}

- (void) resetFetch {
    for (Source *source in (id) sourceList_)
        [source resetFetch];
}

- (NSString *) mappedSectionForPointer:(const char *)section {
    _H<NSString> *mapped;
    
    _profile(Database$mappedSectionForPointer$Cache)
    mapped = &sections_[section];
    _end
    
    if (*mapped == NULL) {
        size_t length(strlen(section));
        char spaced[length + 1];
        
        _profile(Database$mappedSectionForPointer$Replace)
        for (size_t index(0); index != length; ++index)
            spaced[index] = section[index] == '_' ? ' ' : section[index];
        spaced[length] = '\0';
        _end
        
        NSString *string;
        
        _profile(Database$mappedSectionForPointer$stringWithUTF8String)
        string = [NSString stringWithUTF8String:spaced];
        _end
        
        _profile(Database$mappedSectionForPointer$Map)
        string = [SectionMap_ objectForKey:string] ?: string;
        _end
        
        *mapped = string;
    } return *mapped;
}

- (NSArray *)currentFavorites {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FavoritesPackages"];
}

- (void)addPackageToFavoritesList:(Package *)package {
    NSMutableArray *currentFavoritesMutable = [[NSMutableArray alloc] initWithArray:[self currentFavorites]];
    if (!currentFavoritesMutable) {
        currentFavoritesMutable = [[NSMutableArray alloc] init];
    }
    NSString *packageID = package.id;
    if ([currentFavoritesMutable containsObject:packageID]) {
        [currentFavoritesMutable removeObject:packageID];
    } else {
        [currentFavoritesMutable addObject:packageID];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[currentFavoritesMutable copy] forKey:@"FavoritesPackages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
