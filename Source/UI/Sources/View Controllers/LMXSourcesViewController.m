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
#import "APTSourcesManager.h"
#import "APTSourceList.h"

static NSString * const kSourceCellIdentifier = @"kSourceCellIdentifier";

typedef enum : NSUInteger {
    AddSourceStateNone = 0,
    AddSourceStateVerifyingPackageURL,
    AddSourceStateCheckingForWarning,
} AddSourceState;

@interface LMXSourcesViewController ()

@property (strong) UITableView *tableView;
@property (strong, nonatomic) LMXSourcesDataSource *dataSource;
@property (strong) UIBarButtonItem *refreshButton;
@property (strong) UIBarButtonItem *addSourceButton;

@property BOOL hasAppeared;

// Adding Source
@property AddSourceState addSourceState;
@property NSInteger fetchesActive;

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

- (void)showAlertForSourceInput {
    if (self.addSourceState != AddSourceStateNone) {
        NSLog(@"Can't add another repo while one repo add is happening!");
        return;
    }
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

- (void)addSourceWithURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSLog(@"invalid URL: %@", urlString);
        return;
    }
    self.addSourceState = AddSourceStateVerifyingPackageURL;
    
    [self verifySourceURLExists:[url URLByAppendingPathComponent:@"Packages.bz2"]];
    [self verifySourceURLExists:[url URLByAppendingPathComponent:@"Packages.gz"]];
}

- (void)verifySourceURLExists:(NSURL *)url {
    self.fetchesActive += 1;
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
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self responseFromPackagesVerification:response error:error];
                                                });
                                            }];
    [task resume];

}

- (void)responseFromPackagesVerification:(NSURLResponse *)response error:(NSError *)error {
    self.fetchesActive -= 1;
    if (self.addSourceState != AddSourceStateVerifyingPackageURL) {
        return;
    }
    
    if (error) {
        NSLog(@"Error verifying source: %@", error);
        if (self.fetchesActive == 0) {
            [self presentFailedToVerifySourceAlertWithMessage: error.localizedDescription];
        }
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    NSURL *url = [httpResponse.URL URLByDeletingLastPathComponent];
    if (httpResponse.statusCode != 200) {
        NSString *errorMessage;
        errorMessage = [NSString stringWithFormat:@"Expected status from url %@, received: %d",
                        url, (int)httpResponse.statusCode];
        NSLog(@"%@", errorMessage);
        if (self.fetchesActive == 0) {
            [self presentFailedToVerifySourceAlertWithMessage:errorMessage];
        }
        return;
    } else {
        NSLog(@"response: %@", httpResponse);
    }
    
    NSLog(@"verified source %@", url);
    [self checkSourceURLForWarning:url];
}

- (void)presentFailedToVerifySourceAlertWithMessage:(NSString *)message {
    self.addSourceState = AddSourceStateNone;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"VERIFICATION_ERROR", "")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", )
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    
    [self presentViewController:alertController animated:TRUE completion:nil];
}

- (void)checkSourceURLForWarning:(NSURL *)sourceURL {
    self.addSourceState = AddSourceStateCheckingForWarning;
    NSURL *warningURL = [self warningURLForSourceURL:sourceURL];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task = [session dataTaskWithURL:warningURL
                                        completionHandler:^(NSData * _Nullable data,
                                                            NSURLResponse * _Nullable response,
                                                            NSError * _Nullable error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self receivedWarningData:data
                                                             forSourceURL:sourceURL
                                                                    error:error];
                                            });
                                            
                                        }];
    [task resume];
    
}

- (NSURL *)warningURLForSourceURL:(NSURL *)sourceURL {
    NSString *sourceURLString = sourceURL.absoluteString;
    sourceURLString = [sourceURLString substringFromIndex:sourceURL.scheme.length + @"://".length];
    NSURL *cydiaRoot = [NSURL URLWithString:@"https://cydia.saurik.com/"];
    
    NSString *endpoint = [NSString stringWithFormat:@"api/repotag/%@", sourceURLString];
    return [cydiaRoot URLByAppendingPathComponent:endpoint];
}

- (void)receivedWarningData:(NSData *)data forSourceURL:(NSURL *)sourceURL
                      error:(NSError *)error {
    self.addSourceState = AddSourceStateNone;
    if (error) {
        NSLog(@"Error retrieving warning: %@", error);
    } else if (data.length > 0) {
        [self showWarningData:data
                 forSourceURL:sourceURL];
        return;
    }
    
    [self finalizeSourceAdd:sourceURL];
}

- (void)showWarningData:(NSData *)data
           forSourceURL:(NSURL *)sourceURL {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SOURCE_WARNING", "")
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", "")
                                                                                style:UIAlertActionStyleCancel
                                                                                handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ADD_ANYWAY", "")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [self finalizeSourceAdd:sourceURL];
                                                      }]];
    [self presentViewController:alertController animated:TRUE completion:nil];
}

- (void)finalizeSourceAdd:(NSURL *)sourceURL {
    NSLog(@"Finally add: %@", sourceURL);
    [APTSourcesManager.sharedInstance addSource:sourceURL];
    [APTSourcesManager.sharedInstance writeSources];
    [self.dataSource reloadData];
    [self.tableView reloadData];
}

// MARK: - Refresh Sources


- (void)refreshSources {    
    APTSourceList *list = APTSourceList.main;
    [list performUpdateInBackgroundWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
        if (!success) {
            NSLog(@"Loading sources errors: %@", errors);
            return;
        }
        
        NSLog(@"Finish refreshing sources");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataSource reloadData];
            [self.tableView reloadData];
        });
    }];
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
    [self showAlertForSourceInput];
}

- (void)refreshTapped {
    [self refreshSources];
}

@end
