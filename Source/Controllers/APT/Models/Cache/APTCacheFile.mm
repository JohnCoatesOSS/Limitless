//
//  APTCacheFile.m
//  Limitless
//
//  Created on 12/18/16.
//

#import "APTCacheFile.h"
#import "Apt.h"

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

static int count = 0;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable
                                           [_Nonnull])buffer
                                    count:(NSUInteger)len {
    pkgCache::PkgIterator iterator;
    
    if (state->state == 0) {
        NSLog(@"state is 0!");
        iterator = (*_cacheFile)->PkgBegin();
    } else {
        
        const char *name = (const char *)state->state;
        NSLog(@"package name: %s", name);
        iterator = (*_cacheFile)->FindPkg(name);
        // move to next
        ++iterator;
        free((void *)name);
    }
    
    NSUInteger batchCount = 0;
    const char *packageName = iterator.Name();
    
    NSMutableArray *retainDuringIteration = [NSMutableArray new];
    while (!iterator.end() && batchCount < len) {
        
        count += 1;
        packageName = iterator.Name();
        NSString * __autoreleasing packageHolder = @(packageName);
//        [retainDuringIteration addObject:package];
        buffer[batchCount] = packageHolder;
        ++iterator;
        batchCount++;
    }
    
    
    if (iterator.end()) {
        NSLog(@"iterator has ended!");
    }
    
    self.retainDuringIteration = retainDuringIteration;
    if (!iterator.end()) {
        state->state = (unsigned long)strdup(packageName);
    } else {
        state->state = (unsigned long)packageName;
    }
    
    state->itemsPtr = buffer;
    state->mutationsPtr = &state->extra[0];
    
    return batchCount;
}

@end
