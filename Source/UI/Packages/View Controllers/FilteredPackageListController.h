//
//  FilteredPackageListController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Package.h"
#import "PackageListController.h"

typedef Function<bool, Package *> PackageFilter;
typedef Function<void, NSMutableArray *> PackageSorter;
@interface FilteredPackageListController : PackageListController {
    PackageFilter filter_;
    PackageSorter sorter_;
}

- (id) initWithDatabase:(Database *)database title:(NSString *)title filter:(PackageFilter)filter;

- (void) setFilter:(PackageFilter)filter;
- (void) setSorter:(PackageSorter)sorter;

@end
