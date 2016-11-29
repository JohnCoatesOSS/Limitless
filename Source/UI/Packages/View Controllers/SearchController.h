//
//  SearchController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"
#import "FilteredPackageListController.h"

@interface SearchController : FilteredPackageListController <
UISearchBarDelegate
> {
    _H<UISearchBar, 1> search_;
    BOOL searchloaded_;
    bool summary_;
}

- (id) initWithDatabase:(Database *)database query:(NSString *)query;
- (void) reloadData;

@end