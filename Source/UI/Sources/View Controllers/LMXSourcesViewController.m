//
//  LMXSourcesViewController.m
//  Limitless
//
//  Created by John Coates on 12/4/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "LMXSourcesViewController.h"
#import "LMXSourcesDataSource.h"
#import "LMXDevice.h"


static NSString * const kSourceCellIdentifier = @"kSourceCellIdentifier";

@interface LMXSourcesViewController ()

@property (strong) UITableView *tableView;
@property (strong, nonatomic) LMXSourcesDataSource *dataSource;
@property (strong) UIBarButtonItem *refreshButton;
@property (strong) UIBarButtonItem *addSourceButton;

@property BOOL hasAppeared;

@end

@implementation LMXSourcesViewController

// MARK: - Init

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Sources", nil);
        [self navigationItemSetup];
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

// MARK: - UI Setup

- (void)tableViewSetup {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;
    [self.dataSource configureTableWithCellIdentifiers:self.tableView];
    [self.view addSubview:self.tableView];
}

- (void)navigationItemSetup {
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                target:self
                                                                                action:@selector(editTapped)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    _refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(refreshTapped)];
    self.navigationItem.leftBarButtonItem = self.refreshButton;
    
    _addSourceButton = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(addSourceTapped)];
}

// MARK: - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    if ([self.dataSource isSourceAtIndexPathRemovable:indexPath]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

// MARK: - Properties

- (LMXSourcesDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [LMXSourcesDataSource new];
    }
    
    return _dataSource;
}

// MARK: - Add Source

- (void)addSourceWithURL:(NSString *)urlString {
    NSLog(@"adding: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSLog(@"invalid URL: %@", urlString);
        return;
    }
    
    [self checkURLExists:[url URLByAppendingPathComponent:@"Packages.bz2"]];
    [self checkURLExists:[url URLByAppendingPathComponent:@"Packages.gz"]];
    
}

- (void)checkURLExists:(NSURL *)url {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];
    
    request.HTTPMethod = @"HEAD";
    [request setValue:@"X-Machine" forHTTPHeaderField:LMXDevice.machineIdentifier];
    [request setValue:@"X-Unique-ID" forHTTPHeaderField:LMXDevice.uniqueIdentifier];
    
    if ([[url scheme] isEqualToString:@"https"]) {
        [request setValue:@"X-Cydia-Id" forHTTPHeaderField:LMXDevice.uniqueIdentifier];
    }
    
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data,
                                                                NSURLResponse * _Nullable response,
                                                                NSError * _Nullable error) {
                                                if (error) {
                                                    NSLog(@"Error verifying source: %@", error);
                                                    return;
                                                }
                                                
                                                NSLog(@"verifying source response: %@", response);
                                                
                                            }];
    [task resume];

}

// MARK: - Button Taps

- (void)editTapped {
    BOOL editing = !self.tableView.editing;
    [self.tableView setEditing:editing
                      animated:TRUE];
    
    UIBarButtonItem *leftBarButtonItem;
    if (editing) {
        leftBarButtonItem = self.addSourceButton;
    } else {
        leftBarButtonItem = self.refreshButton;
    }
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:TRUE];
}

- (void)addSourceTapped {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ENTER_APT_URL", "")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ADD_SOURCE", "")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          UITextField *textField = alertController.textFields[0];
                                                          [self addSourceWithURL:textField.text];
                                                      }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"http://";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    [self presentViewController:alertController animated:true completion:nil];
    
}

- (void)refreshTapped {
    [self addSourceTapped];
}

@end
