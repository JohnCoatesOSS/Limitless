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
    CFArrayApplyFunction(packages_, CFRangeMake(0, CFArrayGetCount(packages_)), reinterpret_cast<CFArrayApplierFunction>(&CFRelease), NULL);
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
    if (name == nil)
        return nil;
    @synchronized (self) {
        if (static_cast<pkgDepCache *>(cache_) == NULL)
            return nil;
        pkgCache::PkgIterator iterator(cache_->FindPkg([name UTF8String]));
        return iterator.end() ? nil : [Package packageWithIterator:iterator withZone:NULL inPool:NULL database:self];
    } }

- (id) init {
    if ((self = [super init]) != nil) {
        policy_ = NULL;
        records_ = NULL;
        resolver_ = NULL;
        fetcher_ = NULL;
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

- (pkgCacheFile &) cache {
    return cache_;
}

- (pkgDepCache::Policy *) policy {
    return policy_;
}

- (pkgRecords *) records {
    return records_;
}

- (pkgProblemResolver *) resolver {
    return resolver_;
}

- (pkgAcquire &) fetcher {
    return *fetcher_;
}

- (pkgSourceList &) list {
    return *list_;
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

- (bool) popErrorWithTitle:(NSString *)title forReadList:(pkgSourceList &)list {
    if ([self popErrorWithTitle:title forOperation:list.ReadMainList()])
        return true;
    return false;
}

- (void) reloadDataWithInvocation:(NSInvocation *)invocation {
    @synchronized (self) {
        ++era_;
        
        [self releasePackages];
        
        sourceMap_.clear();
        [sourceList_ removeAllObjects];
        
        _error->Discard();
        
        delete list_;
        list_ = NULL;
        manager_ = NULL;
        delete lock_;
        lock_ = NULL;
        delete fetcher_;
        fetcher_ = NULL;
        delete resolver_;
        resolver_ = NULL;
        delete records_;
        records_ = NULL;
        delete policy_;
        policy_ = NULL;
        
        cache_.Close();
        
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
        
        list_ = new pkgSourceList();
        _profile(reloadDataWithInvocation$ReadMainList)
        if ([self popErrorWithTitle:title forReadList:*list_])
            return;
        _end
        
        
        
        _profile(reloadDataWithInvocation$Source$initWithMetaIndex)
        for (pkgSourceList::const_iterator source = list_->begin(); source != list_->end(); ++source) {
            Source *object([[[Source alloc] initWithMetaIndex:*source forDatabase:self inPool:&pool_] autorelease]);
            [sourceList_ addObject:object];
        }
        _end
        
        _trace();
        OpProgress progress;
        bool opened;
    open:
        delock_ = GetStatusDate();
        _profile(reloadDataWithInvocation$pkgCacheFile)
        opened = cache_.Open(progress, false);
        _end
        if (!opened) {
            // XXX: what if there are errors, but Open() == true? this should be merged with popError:
            while (!_error->empty()) {
                std::string error;
                bool warning(!_error->PopMessage(error));
                
                lprintf("cache_.Open():[%s]\n", error.c_str());
                
                [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:error.c_str()] ofType:(warning ? kCydiaProgressEventTypeWarning : kCydiaProgressEventTypeError)] forTask:title];
                
                SEL repair(NULL);
                if (false);
                else if (error == "dpkg was interrupted, you must manually run 'dpkg --configure -a' to correct the problem. ")
                    repair = @selector(configure);
                //else if (error == "The package lists or status file could not be parsed or opened.")
                //    repair = @selector(update);
                // else if (error == "Could not get lock /var/lib/dpkg/lock - open (35 Resource temporarily unavailable)")
                // else if (error == "Could not open lock file /var/lib/dpkg/lock - open (13 Permission denied)")
                // else if (error == "Malformed Status line")
                // else if (error == "The list of sources could not be read.")
                
                if (repair != NULL) {
                    _error->Discard();
                    [delegate_ repairWithSelector:repair];
                    goto open;
                }
            }
            
            return;
        }
        _trace();
        
        unlink("/tmp/cydia.chk");
        
        now_ = [[NSDate date] timeIntervalSince1970];
        
        policy_ = new pkgDepCache::Policy();
        records_ = new pkgRecords(cache_);
        resolver_ = new pkgProblemResolver(cache_);
        fetcher_ = new pkgAcquire(status_);
        lock_ = NULL;
        
        if (cache_->DelCount() != 0 || cache_->InstCount() != 0) {
            [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:UCLocalize("COUNTS_NONZERO_EX") ofType:kCydiaProgressEventTypeError] forTask:title];
            return;
        }
        
        _profile(reloadDataWithInvocation$pkgApplyStatus)
        if ([self popErrorWithTitle:title forOperation:pkgApplyStatus(cache_)])
            return;
        _end
        
        if (cache_->BrokenCount() != 0) {
            _profile(pkgApplyStatus$pkgFixBroken)
            if ([self popErrorWithTitle:title forOperation:pkgFixBroken(cache_)])
                return;
            _end
            
            if (cache_->BrokenCount() != 0) {
                [delegate_ addProgressEventOnMainThread:[CydiaProgressEvent eventWithMessage:UCLocalize("STILL_BROKEN_EX") ofType:kCydiaProgressEventTypeError] forTask:title];
                return;
            }
            
            _profile(pkgApplyStatus$pkgMinimizeUpgrade)
            if ([self popErrorWithTitle:title forOperation:pkgMinimizeUpgrade(cache_)])
                return;
            _end
        }
        
        for (Source *object in (id) sourceList_) {
            metaIndex *source([object metaIndex]);
            std::vector<pkgIndexFile *> *indices = source->GetIndexFiles();
            for (std::vector<pkgIndexFile *>::const_iterator index = indices->begin(); index != indices->end(); ++index)
                // XXX: this could be more intelligent
                if (dynamic_cast<debPackagesIndex *>(*index) != NULL) {
                    pkgCache::PkgFileIterator cached((*index)->FindInCache(cache_));
                    if (!cached.end())
                        sourceMap_[cached->ID] = object;
                }
        }
        
        {
            /*std::vector<Package *> packages;
             packages.reserve(std::max(10000U, [packages_ count] + 1000));
             packages_ = nil;*/
            
            _profile(reloadDataWithInvocation$packageWithIterator)
            for (pkgCache::PkgIterator iterator = cache_->PkgBegin(); !iterator.end(); ++iterator)
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
        delete resolver_;
        resolver_ = new pkgProblemResolver(cache_);
        
        for (pkgCache::PkgIterator iterator(cache_->PkgBegin()); !iterator.end(); ++iterator)
            if (!cache_[iterator].Keep())
                cache_->MarkKeep(iterator, false);
            else if ((cache_[iterator].iFlags & pkgDepCache::ReInstall) != 0)
                cache_->SetReInstall(iterator, false);
    } }

- (void) configure {
    NSString *dpkg = [NSString stringWithFormat:@"/Applications/Limitless.app/runAsSuperuser --configure -a --status-fd %u", statusfd_];
    _trace();
    system([dpkg UTF8String]);
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
        
        pkgAcquire fetcher;
        fetcher.Clean(_config->FindDir("Dir::Cache::Archives"));
        
        CydiaLogCleaner cleaner;
        if ([self popErrorWithTitle:title forOperation:cleaner.Go(_config->FindDir("Dir::Cache::Archives") + "partial/", cache_)])
            return false;
        
        return true;
    } }

- (bool) prepare {
    fetcher_->Shutdown();
    
    pkgRecords records(cache_);
    
    lock_ = new FileFd();
    lock_->Fd(GetLock(_config->FindDir("Dir::Cache::Archives") + "lock"));
    
    NSString *title(UCLocalize("PREPARE_ARCHIVES"));
    
    if ([self popErrorWithTitle:title])
        return false;
    
    pkgSourceList list;
    if ([self popErrorWithTitle:title forReadList:list])
        return false;
    
    manager_ = (_system->CreatePM(cache_));
    if ([self popErrorWithTitle:title forOperation:manager_->GetArchives(fetcher_, &list, &records)])
        return false;
    
    return true;
}

- (void) perform {
    bool substrate(RestartSubstrate_);
    RestartSubstrate_ = false;
    
    NSString *title(UCLocalize("PERFORM_SELECTIONS"));
    
    NSMutableArray *before = [NSMutableArray arrayWithCapacity:16]; {
        pkgSourceList list;
        if ([self popErrorWithTitle:title forReadList:list])
            return;
        for (pkgSourceList::const_iterator source = list.begin(); source != list.end(); ++source)
            [before addObject:[NSString stringWithUTF8String:(*source)->GetURI().c_str()]];
    }
    
    [delegate_ performSelectorOnMainThread:@selector(retainNetworkActivityIndicator) withObject:nil waitUntilDone:YES];
    
    if (fetcher_->Run(PulseInterval_) != pkgAcquire::Continue) {
        _trace();
        [self popErrorWithTitle:title];
        return;
    }
    
    bool failed = false;
    for (pkgAcquire::ItemIterator item = fetcher_->ItemsBegin(); item != fetcher_->ItemsEnd(); item++) {
        if ((*item)->Status == pkgAcquire::Item::StatDone && (*item)->Complete)
            continue;
        if ((*item)->Status == pkgAcquire::Item::StatIdle)
            continue;
        
        std::string uri = (*item)->DescURI();
        std::string error = (*item)->ErrorText;
        
        lprintf("pAf:%s:%s\n", uri.c_str(), error.c_str());
        failed = true;
        
        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:error.c_str()] ofType:kCydiaProgressEventTypeError]);
        [delegate_ addProgressEventOnMainThread:event forTask:title];
    }
    
    [delegate_ performSelectorOnMainThread:@selector(releaseNetworkActivityIndicator) withObject:nil waitUntilDone:YES];
    
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
    
    pkgPackageManager::OrderResult result(manager_->DoInstall(statusfd_));
    
    NSString *oextended(@"/var/lib/apt/extended_states");
    NSString *nextended(Cache("extended_states"));
    
    struct stat info;
    if (stat([nextended UTF8String], &info) != -1 && (info.st_mode & S_IFMT) == S_IFREG) {
        if (![Device isSimulator]) {
            system([[NSString stringWithFormat:@"/Applications/Limitless.app/runAsSuperuser /bin/cp --remove-destination %@ %@", ShellEscape(nextended), ShellEscape(oextended)] UTF8String]);
        }
    }
    
    unlink([nextended UTF8String]);
    symlink([oextended UTF8String], [nextended UTF8String]);
    
    if ([self popErrorWithTitle:title])
        return;
    
    if (result == pkgPackageManager::Failed) {
        _trace();
        return;
    }
    
    if (result != pkgPackageManager::Completed) {
        _trace();
        return;
    }
    
    NSMutableArray *after = [NSMutableArray arrayWithCapacity:16]; {
        pkgSourceList list;
        if ([self popErrorWithTitle:title forReadList:list])
            return;
        for (pkgSourceList::const_iterator source = list.begin(); source != list.end(); ++source)
            [after addObject:[NSString stringWithUTF8String:(*source)->GetURI().c_str()]];
    }
    
    if (![before isEqualToArray:after])
        [self update];
}

- (bool) delocked {
    return ![delock_ isEqual:GetStatusDate()];
}

- (bool) upgrade {
    NSString *title(UCLocalize("UPGRADE"));
    if ([self popErrorWithTitle:title forOperation:pkgDistUpgrade(cache_)])
        return false;
    return true;
}

- (void) update {
    [self updateWithStatus:*status_];
}

- (void) updateWithStatus:(CancelStatus &)status {
    NSString *title(UCLocalize("REFRESHING_DATA"));
    
    pkgSourceList list;
    if ([self popErrorWithTitle:title forReadList:list])
        return;
    
    FileFd lock;
    lock.Fd(GetLock(_config->FindDir("Dir::State::Lists") + "lock"));
    if ([self popErrorWithTitle:title])
        return;
    
    [delegate_
     performSelectorOnMainThread:@selector(retainNetworkActivityIndicator)
     withObject:nil waitUntilDone:YES];    
    
    bool success(ListUpdate(status, list, PulseInterval_));
    if (status.WasCancelled())
        _error->Discard();
    else {
        [self popErrorWithTitle:title forOperation:success];
        
        [[NSDictionary dictionaryWithObjectsAndKeys:
          [NSDate date], @"LastUpdate",
          nil] writeToFile:[Paths cacheState] atomically:YES];
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

@end
