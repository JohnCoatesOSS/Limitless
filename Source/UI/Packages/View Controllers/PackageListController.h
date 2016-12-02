//
//  PackageListController.h
//  Cydia
//
//  Created on 8/30/16.
//
#import "Menes/Menes.h"
#import "Database.h"

@class Package;

@interface PackageListController : CyteViewController
<UITableViewDataSource,UITableViewDelegate> {
    _transient Database *database_;
    unsigned era_;
    _H<NSArray> packages_;
    _H<NSArray> sections_;
    _H<UITableView, 2> list_;
    
    _H<NSArray> thumbs_;
    NSArray <NSNumber *> *_sectionsForIndexTitles;
    
    _H<NSString> title_;
    unsigned reloading_;
}
@property (nonatomic, strong) id previewingContext;

- (id) initWithDatabase:(Database *)database title:(NSString *)title;
- (void) setDelegate:(id)delegate;
- (void) resetCursor;
- (void) clearData;

- (NSArray *) sectionsForPackages:(NSMutableArray *)packages;

- (void) didSelectPackage:(Package *)package;
- (void)updateInstalledListIfNeeded:(BOOL)needed;

@end
