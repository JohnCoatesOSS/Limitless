//
//  CatalogTableViewController
//  Feature Catalog
//
//

#import "CatalogTableViewController.h"
#import "LMXRespringViewController.h"

@interface CatalogTableViewController ()

@property NSString *cellIdentifier;

@end

@implementation CatalogTableViewController

// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Features";
    self.automaticallyAdjustsScrollViewInsets = FALSE;
    self.cellIdentifier = @"cellIdentifier";
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:self.cellIdentifier];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
}

// MARK: - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = @"Respring";
    return cell;
}

// MARK: - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController = [LMXRespringViewController new];
    [self.navigationController pushViewController:viewController
                                         animated:TRUE];
}

@end
