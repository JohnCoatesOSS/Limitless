//
//  LMXRespringViewController.m
//  Limitless
//
//   12/1/16.
//

#import "LMXRespringViewController.h"

@interface LMXRespringViewController ()

@end

@implementation LMXRespringViewController

// MARK: - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpBackgroundView];
    [self setUpLogoView];
    [self setUpRefreshingText];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation:TRUE];
    [self setNeedsStatusBarAppearanceUpdate];
    
    // for when contained in feature catalog
    // setting hidden specifically on navigationBar retains swipe back ability
    self.navigationController.navigationBar.hidden = TRUE;
}

- (void)viewWillDisappear:(BOOL)animated {
    // for when contained in feature catalog
    self.navigationController.navigationBar.hidden = FALSE;
}

// MARK: - View Setups

- (void)setUpBackgroundView {
    UIImage *backgroundImage = [UIImage imageNamed:@"respringBackground"];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.frame = self.view.bounds;
    [self.view addSubview:backgroundView];
}

- (void)setUpLogoView {
    UIView *container = [UIView new];
    container.accessibilityIdentifier = @"logoContainer";
    UIImage *logoImage = [UIImage imageNamed:@"respringLogo"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    [container addSubview:logoImageView];
    [self.view addSubview:container];
    
    container.translatesAutoresizingMaskIntoConstraints = false;
    logoImageView.translatesAutoresizingMaskIntoConstraints = false;
    
    [container.widthAnchor constraintGreaterThanOrEqualToAnchor:logoImageView.widthAnchor].active = YES;
    [container.heightAnchor constraintGreaterThanOrEqualToAnchor:logoImageView.heightAnchor].active = YES;
    [logoImageView.centerXAnchor constraintEqualToAnchor:container.centerXAnchor].active = YES;
    [logoImageView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-45].active = YES;
    
    [container.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [container.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
}

- (void)setUpRefreshingText {
    NSString *text = NSLocalizedStringWithDefaultValue(@"REFRESHING_SYSTEM", nil, [NSBundle mainBundle],
                                                       @"Refreshing system...", @"Shown when respringing.");
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    label.textColor = UIColor.whiteColor;
    label.text = text;
    
    [self.view addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = false;
    [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-45].active = YES;
}

// MARK: - Status Bar

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
