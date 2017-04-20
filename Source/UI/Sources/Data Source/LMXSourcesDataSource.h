//
//  LMXSourcesDataSource
//  Limitless
//
//  Created on 12/5/16.
//

@class LMXAPTSource;

@interface LMXSourcesDataSource : NSObject <UITableViewDataSource>

@property (nonnull) NSArray <LMXAPTSource *> *sources;

- (void)configureTableWithCellIdentifiers:(nonnull UITableView *)tableView;

- (void)reloadData;

// Editing

- (BOOL)isSourceAtIndexPathRemovable:(nonnull NSIndexPath *)indexPath;

@end
