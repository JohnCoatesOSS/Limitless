//
//  CatalogTableViewController
//  Feature Catalog
//
//

#import "CatalogTableViewController.h"
#import "LMXRespringViewController.h"
#import "LMXSourcesViewController.h"

@interface CatalogTableViewController ()

@property NSString *cellIdentifier;
@property NSArray<NSString *> *features;
@property BOOL hasAppeared;
@end

static NSString * const kFeatureRespring = @"Respring Screen";
static NSString * const kFeatureSources = @"Sources Screen";

@implementation CatalogTableViewController

// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Features";
    self.automaticallyAdjustsScrollViewInsets = FALSE;
    self.cellIdentifier = @"cellIdentifier";
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:self.cellIdentifier];
    
    self.features = @[
                      kFeatureRespring,
                      kFeatureSources
                      ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.hasAppeared) {
        return;
    }
    self.hasAppeared = true;
    
    NSString *savedFeature = [self savedFeatureSelection];
    if (savedFeature) {
        [self selectedFeature:savedFeature];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
}

// MARK: - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.features.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = self.features[indexPath.row];
    return cell;
}

// MARK: - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *feature = self.features[indexPath.row];
    [self saveFeatureSelection:feature];
    [self selectedFeature:feature];
}

// MARK: - Feature Selection

- (void)selectedFeature:(nonnull NSString *)feature {
    UIViewController *viewController;
    if ([feature isEqualToString:kFeatureRespring]) {
        viewController = [LMXRespringViewController new];
    }
    else if ([feature isEqualToString:kFeatureSources]) {
        viewController = [LMXSourcesViewController new];
    }
    
    [self.navigationController pushViewController:viewController
                                         animated:TRUE];
}

// MARK: - Saving/Loading State

static NSString *kSavedSettingFeature = @"selectedFeature";

- (void)saveFeatureSelection:(nonnull NSString *)feature {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:feature forKey:kSavedSettingFeature];
    [userDefaults synchronize];
}

- (nullable NSString *)savedFeatureSelection {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSavedSettingFeature];
}

@end
