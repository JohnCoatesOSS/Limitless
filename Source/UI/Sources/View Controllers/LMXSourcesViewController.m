//
//  LMXSourcesViewController.m
//  Limitless
//
//  Created by John Coates on 12/4/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "LMXSourcesViewController.h"
#import "LMXSourcesDataSource.h"


static NSString * const kSourceCellIdentifier = @"kSourceCellIdentifier";

@interface LMXSourcesViewController ()

@property (strong) UITableView *tableView;
@property (strong, nonatomic) LMXSourcesDataSource *dataSource;
@property BOOL hasAppeared;

@end

@implementation LMXSourcesViewController

// MARK: - Init

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Sources", nil);
    }
    return self;
}

// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tableViewSetup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.hasAppeared) {
        return;
    }
    self.hasAppeared = TRUE;
}

// MARK: - View Setups

- (void)tableViewSetup {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self.dataSource;
    [self.dataSource configureTableWithCellIdentifiers:self.tableView];
    [self.view addSubview:self.tableView];
}

// MARK: - Properties

- (LMXSourcesDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [LMXSourcesDataSource new];
    }
    
    return _dataSource;
}


// MARK: - Button Taps

- (void)editButtonTapped {
    
}

@end
