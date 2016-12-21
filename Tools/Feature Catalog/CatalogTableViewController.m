//
//  CatalogTableViewController
//  Feature Catalog
//
//

#import "CatalogTableViewController.h"
#import "LMXRespringViewController.h"
#import "LMXSourcesViewController.h"
#import "FeatureCatalogSection.h"
#import "FeatureCatalogItem.h"
#import "SettingsViewController.h"

@interface CatalogTableViewController ()

@property NSString *cellIdentifier;
@property NSArray<NSString *> *features;
@property (nonatomic) NSArray<FeatureCatalogSection *> *sections;

@property BOOL hasAppeared;
@end

@implementation CatalogTableViewController

// MARK: - Init

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        
    }
    
    return self;
}


// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Features";
    self.automaticallyAdjustsScrollViewInsets = FALSE;
    self.cellIdentifier = @"cellIdentifier";
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:self.cellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.hasAppeared) {
        return;
    }
    self.hasAppeared = true;
    
    FeatureCatalogItem *savedSelection = [self savedSelection];
    if (savedSelection) {
        [self selectedItem:savedSelection];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
}

// MARK: - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                            forIndexPath:indexPath];
    FeatureCatalogItem *item;
    item = self.sections[indexPath.section].items[indexPath.row];
    cell.textLabel.text = item.name;
    return cell;
}

// MARK: - Table View Delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FeatureCatalogItem *item;
    item = self.sections[indexPath.section].items[indexPath.row];
    
    [self saveSelection:item];
    [self selectedItem:item];
}

// MARK: - Item Selection

- (void)selectedItem:(nonnull FeatureCatalogItem *)item {
    
    UIViewController *viewController = item.creationBlock();
    [self.navigationController pushViewController:viewController
                                         animated:TRUE];
}

// MARK: - Save / Load Selection

static NSString *kSavedSettingItem = @"selectedItem";

- (void)saveSelection:(nonnull FeatureCatalogItem *)item {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:item.name forKey:kSavedSettingItem];
    [userDefaults synchronize];
}

- (FeatureCatalogItem *)savedSelection {
    NSString *savedItemName;
    savedItemName = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedSettingItem];
    if (!savedItemName) {
        return nil;
    }
    
    for (FeatureCatalogSection *section in self.sections) {
        for (FeatureCatalogItem *item in section.items) {
            if ([item.name isEqualToString:savedItemName]) {
                return item;
            }
        }
    }
    
    return nil;
}

// MARK: - Items

- (NSArray<FeatureCatalogSection *> *)sections {
    if (_sections) {
        return _sections;
    }
    
    _sections = @[
                  [self home],
                  [self tabs],
                  [self utilities],
                  ];
    return _sections;
}

// MARK: - Sections

- (FeatureCatalogSection *)home {
    FeatureCatalogSection *section = [[FeatureCatalogSection alloc] initWithTitle:@"Home"];
    
    section.items = @[
                      [[FeatureCatalogItem alloc] initWithName:@"Settings" creationBlock:^UIViewController *{
                          return [SettingsViewController new]; }]
                      ];
    
    return section;
}


- (FeatureCatalogSection *)utilities {
    FeatureCatalogSection *section = [[FeatureCatalogSection alloc] initWithTitle:@"Utilities"];
    
    section.items = @[
                      [[FeatureCatalogItem alloc] initWithName:@"Respring Screen" creationBlock:^UIViewController *{
                          return [LMXRespringViewController new]; }]
                      ];
    
    return section;
}

- (FeatureCatalogSection *)tabs {
    FeatureCatalogSection *section = [[FeatureCatalogSection alloc] initWithTitle:@"Tabs"];
    
    section.items = @[
                      [[FeatureCatalogItem alloc] initWithName:@"Sources" creationBlock:^UIViewController *{
                          return [LMXSourcesViewController new]; }]
                      ];
    
    return section;
}

@end
