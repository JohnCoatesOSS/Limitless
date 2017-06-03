//
//  Database.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Menes/Menes.h"
#import "Standard.h"
#import "Apt.h"

#import "UIGlobals.h"
#import "GeneralGlobals.h"
#import "Localize.h"
#import "Delegates.h"
#import "ProgressEvent.h"

#import "CancelStatus.hpp"
#import "CydiaStatus.hpp"

typedef std::map< unsigned long, _H<Source> > SourceMap;

@interface Database : NSObject {
    NSZone *zone_;
    CYPool pool_;
    
    unsigned era_;
    _H<NSDate> delock_;
    
    FileFd *lock_;
    
    SourceMap sourceMap_;
    _H<NSMutableArray> sourceList_;
    
    CFMutableArrayRef packages_;
    
    _transient NSObject<DatabaseDelegate> *delegate_;
    _transient NSObject<ProgressDelegate> *progress_;
    
    CydiaStatus *status_;
    
    int cydiafd_;
    int statusfd_;
    FILE *input_;
    
    std::map<const char *, _H<NSString> > sections_;
}

+ (Database *) sharedInstance;
- (unsigned) era;

- (void) _readCydia:(NSNumber *)fd;
- (void) _readStatus:(NSNumber *)fd;
- (void) _readOutput:(NSNumber *)fd;

- (FILE *) input;

- (Package *) packageWithName:(NSString *)name;

@property (retain, strong) APTCacheFile *cacheFile;
@property (retain, strong) APTDependencyCachePolicy *policy;
@property (retain, strong) APTPackageProblemResolver *problemResolver;
@property (retain, strong) APTRecords *packageRecords;
@property (retain, strong) APTDownloadScheduler *downloadScheduler;
@property (retain, strong) APTPackageManager *packageManager;
@property (retain, strong) APTSourceList *sourceListController;

- (NSArray *) packages;
- (NSArray *) sources;
- (Source *) sourceWithKey:(NSString *)key;
- (void) reloadDataWithInvocation:(NSInvocation *)invocation;

- (void) clear;
- (void) configure;
- (bool) clean;
- (bool) prepare;
- (void) perform;
- (bool) delocked;
- (bool) upgrade;
- (void) update;

- (void) updateWithStatus:(CancelStatus &)status;

- (void) setDelegate:(NSObject<DatabaseDelegate> *)delegate;

- (void) setProgressDelegate:(NSObject<ProgressDelegate> *)delegate;
- (NSObject<ProgressDelegate> *) progressDelegate;

- (Source *) getSource:(pkgCache::PkgFileIterator)file;
- (void) setFetch:(bool)fetch forURI:(const char *)uri;
- (void) resetFetch;

- (NSString *) mappedSectionForPointer:(const char *)pointer;

- (NSArray *)currentFavorites;
- (void)addPackageToFavoritesList:(Package *)package;

@end
