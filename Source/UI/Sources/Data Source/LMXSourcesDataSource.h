//
//  LMXSourcesDataSource
//  Limitless
//
//  Created on 12/5/16.
//

@class APTSource;

@interface LMXSourcesDataSource : NSObject <UITableViewDataSource>

@property (nonnull, copy) NSArray <APTSource *> *sources;

- (void)configureTableWithCellIdentifiers:(nonnull UITableView *)tableView;

- (void)reloadData;

// Editing

- (BOOL)isSourceAtIndexPathRemovable:(nonnull NSIndexPath *)indexPath;

@end
