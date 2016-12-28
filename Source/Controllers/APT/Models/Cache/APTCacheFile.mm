//
//  APTCacheFile.m
//  Limitless
//
//  Created on 12/18/16.
//

#import "APTCacheFile-Private.h"
#import "Apt.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTCacheFile ()

@property pkgCacheFile *cacheFile;
@property OpProgress *progress;
@property (nonatomic) NSNumber *packagesCount;
@property NSArray *retainDuringIteration;

@end

@implementation APTCacheFile

// MARK: - Init

- (instancetype)initWithError:(NSError **)error {
    self = [super init];

    if (self) {
        _progress = new OpProgress();
        _cacheFile = new pkgCacheFile();
        bool lockCacheFile = false;
        if (!_cacheFile->Open(*_progress, lockCacheFile)) {
            *error = [APTErrorController popError];
            return nil;
        }
    }

    return self;
}

- (void)dealloc {
    _cacheFile->Close();
    delete _cacheFile;
    delete _progress;
}

- (NSNumber *)packagesCount {
    if (_packagesCount) {
        return _packagesCount;
    }
    
    pkgCacheFile cacheFile = *_cacheFile;
    int packages = 0;
    for (pkgCache::PkgIterator iterator = cacheFile->PkgBegin(); !iterator.end(); iterator++) {
        packages += 1;
    }
    
    _packagesCount = @(packages);
    return _packagesCount;
}
typedef struct APTPackageEnumerationState {
    pkgCache *owner;
    pkgCache::Package *package;
    long hashIndex;
} APTPackageEnumerationState;
static unsigned long APTPackageEnumerationStateFinished = ULONG_MAX;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable
                                           [_Nonnull])buffer
                                    count:(NSUInteger)len {
    if (state->state == APTPackageEnumerationStateFinished) {
        return 0;
    }
    
    APTPackageEnumerationState *enumerationState = nil;
    
    pkgCache::PkgIterator iterator;
    if (state->state == 0) {
        enumerationState = (APTPackageEnumerationState *)malloc(sizeof(APTPackageEnumerationState));
        iterator = (*_cacheFile)->PkgBegin();
    } else {
        enumerationState = (APTPackageEnumerationState *)state->state;
        iterator = pkgCache::PkgIterator(*enumerationState->owner,
                                         enumerationState->package,
                                         enumerationState->hashIndex);
    }
    
    NSUInteger bufferIndex = 0;
    while (!iterator.end() && bufferIndex < len) {
        NSString * __autoreleasing packageHolder = @(iterator.Name());
        buffer[bufferIndex] = packageHolder;
        iterator++;
        bufferIndex++;
    }
    
    if (iterator.end()) {
        if (enumerationState != nil) {
            free(enumerationState);
        }
        state->state = APTPackageEnumerationStateFinished;
    } else {
        enumerationState->owner = iterator.getOwner();
        enumerationState->package = iterator.getPackage();
        enumerationState->hashIndex = iterator.getHashIndex();
        
        state->state = (unsigned long)enumerationState;
    }
    state->itemsPtr = buffer;
    state->mutationsPtr = &state->extra[0];
    
    return bufferIndex;
}


// MARK: - Read Only Properties

- (unsigned long)pendingDeletions {
    return (*_cacheFile)->DelCount();
}

- (unsigned long)pendingInstalls {
    return (*_cacheFile)->InstCount();
}

- (unsigned long)brokenPackages {
    return (*_cacheFile)->BrokenCount();
}



@end

APT_SILENCE_DEPRECATIONS_END
