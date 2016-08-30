//
//  FilteredPackageListController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "FilteredPackageListController.h"

@implementation FilteredPackageListController

- (void) setFilter:(PackageFilter)filter {
    @synchronized (self) {
        filter_ = filter;
    } }

- (void) setSorter:(PackageSorter)sorter {
    @synchronized (self) {
        sorter_ = sorter;
    } }

- (NSMutableArray *) _reloadPackages {
    @synchronized (database_) {
        era_ = [database_ era];
        
        NSArray *packages([database_ packages]);
        NSMutableArray *filtered([NSMutableArray arrayWithCapacity:[packages count]]);
        
        PackageFilter filter;
        PackageSorter sorter;
        
        @synchronized (self) {
            filter = filter_;
            sorter = sorter_;
        }
        
        _profile(PackageTable$reloadData$Filter)
        for (Package *package in packages)
            if (filter(package))
                [filtered addObject:package];
        _end
        
        if (sorter)
            sorter(filtered);
        return filtered;
    } }

- (id) initWithDatabase:(Database *)database title:(NSString *)title filter:(PackageFilter)filter {
    if ((self = [super initWithDatabase:database title:title]) != nil) {
        [self setFilter:filter];
    } return self;
}

@end