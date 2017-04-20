//
//  LMXSourcesDataSource
//  Limitless
//
//  Created on 12/5/16.
//

#import "LMXSourcesDataSource.h"
#import "LMXSourceCell.h"
#import "APTManager.h"
#import "APTSource.h"

@interface LMXSourcesDataSource ()

@end

static NSString * const kSourceCellIdentifier = @"SourceCellIdentifier";
typedef enum : NSUInteger {
    SectionAllSources,
    SectionIndividualSources
} Sections;

@implementation LMXSourcesDataSource

// MARK: - Init

- (instancetype)init {
    self = [super init];

    if (self) {
        _sources = @[];
        [self readSources];
    }

    return self;
}

- (void)readSources {
    NSError *error = nil;
    self.sources = [[APTManager sharedInstance] readSourcesWithError:&error];
    if (error) {
        [NSException raise:@"Error Reading Sources" format:@"%@", error];
    }
}

// MARK: - Refreshing

- (void)reloadData {
    [self readSources];
}

// MARK: - Configure Table

- (void)configureTableWithCellIdentifiers:(UITableView *)tableView {
    [tableView registerClass:[LMXSourceCell class]
      forCellReuseIdentifier:kSourceCellIdentifier];
}

// MARK: - Table Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SectionAllSources:
            return 1;
        case SectionIndividualSources:
            return self.sources.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMXSourceCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:kSourceCellIdentifier
                                           forIndexPath:indexPath];
    
    if (indexPath.section == SectionAllSources) {
        cell.allSources = TRUE;
        return cell;
    }
    
    APTSource *source = self.sources[indexPath.row];
    cell.source = source;
    
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SectionIndividualSources:
            return NSLocalizedString(@"INDIVIDUAL_SOURCES", "");
        default:
            return nil;
            
    }
}

// MARK: - Editing

- (BOOL)isSourceAtIndexPathRemovable:(NSIndexPath *)indexPath {
    if (indexPath.section == SectionAllSources) {
        return FALSE;
    }
    
    APTSource *source = self.sources[indexPath.row];
    NSString *host = source.releaseBaseURL.host.lowercaseString;
    if ([host isEqualToString:@"apt.saurik.com"]) {
        return FALSE;
    }
    
    return TRUE;
}

@end
