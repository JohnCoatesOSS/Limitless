//
//  APTSourceList.m
//  Limitless
//
//  Created on 12/17/16.
//

#import "APTSourceList.h"
#import "Apt.h"
#import "APTSource+APTLib.h"
#import "LMXAPTStatus.hpp"


@interface APTSourceList ()

@property (strong, nonatomic) NSArray<APTSource *> *sources;
@property pkgSourceList *list;

@end

@implementation APTSourceList

// MARK: - Convenience Initializers

+ (instancetype)main {
    static dispatch_once_t onceToken;
    static APTSourceList *mainList;
    dispatch_once(&onceToken, ^{
        mainList = [[APTSourceList alloc] initWithMainList];
    });
    return mainList;
}

// MARK: - Initializers

- (instancetype)initWithListFilePath:(NSString *)filePath {
    self = [self initList];

    if (self) {
        _list->Read(string(filePath.UTF8String));
    }

    return self;
}

- (instancetype)initWithMainList {
    self = [self initList];
    
    if (self) {
        _list->ReadMainList();
    }
    
    return self;
}

- (instancetype)initList {
    self = [super init];
    
    if (self) {
        _list = new pkgSourceList();
    }
    
    return self;
}

- (instancetype)init {
    NSString *exceptionReason = [NSString stringWithFormat:@"-init is not an implemented initializer for clas %@",
                                 NSStringFromClass(self.class)];
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:exceptionReason
                                 userInfo:nil];
    return nil;
}

- (NSArray<APTSource *> *)sources {
    if (_sources) {
        return _sources;
    }
    
    
    NSMutableArray *sources = [NSMutableArray new];
    pkgSourceList *list = self.list;
    pkgSourceList::const_iterator currentSource = list->begin();
    
    for (; currentSource != list->end(); currentSource += 1) {
        NSLog(@"source!");
        APTSource *source = [[APTSource alloc] initWithMetaIndex:*currentSource];
        if (!source) {
            continue;
        }
        [sources addObject:source];
    }
    
    _sources = sources;
    return _sources;
}

- (void)performUpdateInBackground {
    [self performUpdateInBackgroundWithCompletion:nil];
}
- (void)performUpdateInBackgroundWithCompletion:(SourcesUpdateCompletion)completion {
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(backgroundQueue, ^{
        [self performUpdateWithCompletion:completion];
    });
}

- (void)performUpdateWithCompletion:(SourcesUpdateCompletion)completion {
    OpProgress progress;
    pkgCacheFile cache;
    bool cacheOpened = cache.Open(progress, false);
    if (!cacheOpened) {
        completion(FALSE, [APTErrorController popErrors]);
        return;
    }
    
    LMXAptStatus *status = new LMXAptStatus();
    pkgAcquire *fetcher = new pkgAcquire(status);
    pkgRecords *records = new pkgRecords(cache);
    
    pkgPackageManager *manager = _system->CreatePM(cache);
    
    void (^deleteVariables)() = ^void() {
        delete records;
        delete fetcher;
        delete status;
    };
    
    pkgSourceList sourceList;
    if (!sourceList.ReadMainList()) {
        completion(FALSE, [APTErrorController popErrors]);
        deleteVariables();
        return;
    }
    
    manager->GetArchives(fetcher, &sourceList, records);
    ListUpdate(*status, sourceList);
    
    int PulseInterval = 500000;
    if (fetcher->Run(PulseInterval) != pkgAcquire::Continue) {
        NSLog(@"fetcher errors: %@", [APTErrorController popErrors]);
        completion(FALSE, [APTErrorController popErrors]);
        deleteVariables();
        return;
    }
    
    bool failed = false;
    NSMutableArray *errors = [NSMutableArray new];
    for (pkgAcquire::ItemIterator item = fetcher->ItemsBegin(); item != fetcher->ItemsEnd(); item++) {
        if ((*item)->Status == pkgAcquire::Item::StatDone && (*item)->Complete)
            continue;
        if ((*item)->Status == pkgAcquire::Item::StatIdle)
            continue;
        
        failed = true;
        std::string uri = (*item)->DescURI();
        std::string errorString = (*item)->ErrorText;
        
        NSLog(@"pAf:%s:%s\n", uri.c_str(), errorString.c_str());
        
        NSString *errorMessage = @(errorString.c_str());
        APTError *error = [APTError unknownErrorWithMessage:errorMessage];
        [errors addObject:error];
    }
    
    if (failed) {
        [errors addObjectsFromArray:[APTErrorController popErrors]];
        completion(FALSE, errors);
        deleteVariables();
        return;
    }
    
    completion(TRUE, [APTErrorController popErrors]);
    deleteVariables();
    return;
}


// MARK: - Dealloc

- (void)dealloc {
    if (_list) {
        delete _list;
        _list = nil;
    }
}

@end
