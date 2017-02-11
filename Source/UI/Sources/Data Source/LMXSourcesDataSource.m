//
//  LMXSourcesDataSource
//  Limitless
//
//  Created on 12/5/16.
//

#import "LMXSourcesDataSource.h"
#import "LMXSourceCell.h"

@interface LMXSourcesDataSource ()

@end

static NSString * const kSourceCellIdentifier = @"SourceCellIdentifier";

@implementation LMXSourcesDataSource

// MARK: - Init

- (instancetype)init {
    self = [super init];

    if (self) {

    }

    return self;
}

// MARK: - Configure Table

- (void)configureTableWithCellIdentifiers:(UITableView *)tableView {
    [tableView registerClass:[LMXSourceCell class]
      forCellReuseIdentifier:kSourceCellIdentifier];
}

// MARK: - Table Data Source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
