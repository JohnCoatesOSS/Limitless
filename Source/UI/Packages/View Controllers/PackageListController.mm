//
//  PackageListController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "PackageListController.h"
#import "DisplayHelpers.hpp"
#import "UIGlobals.h"
#import "Section.h"
#import "CYPackageController.h"
#import "PackageCell.h"
#import "InstalledController.h"
#import "SwipeActionController.h"

@implementation PackageListController

- (NSURL *) referrerURL {
    return [self navigationURL];
}

- (bool) isSummarized {
    return false;
}

- (bool) showsSections {
    return true;
}

- (void) deselectWithAnimation:(BOOL)animated {
    [list_ deselectRowAtIndexPath:[list_ indexPathForSelectedRow] animated:animated];
}

- (void) resizeForKeyboardBounds:(CGRect)bounds duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve {
    CGRect base = [[self view] bounds];
    base.size.height -= bounds.size.height;
    base.origin = [list_ frame].origin;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    [list_ setFrame:base];
    [UIView commitAnimations];
}

- (void) resizeForKeyboardBounds:(CGRect)bounds duration:(NSTimeInterval)duration {
    [self resizeForKeyboardBounds:bounds duration:duration curve:UIViewAnimationCurveLinear];
}

- (void) resizeForKeyboardBounds:(CGRect)bounds {
    [self resizeForKeyboardBounds:bounds duration:0];
}

- (void) getKeyboardCurve:(UIViewAnimationCurve *)curve duration:(NSTimeInterval *)duration forNotification:(NSNotification *)notification {
    BOOL iOSVersionIsGreaterThanOrEqualTo3 = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_3_0;
    BOOL keyboardAnimationCurveIsAvailable = iOSVersionIsGreaterThanOrEqualTo3;
    
    if (keyboardAnimationCurveIsAvailable) {
        id curveValue = [notification.userInfo
                    objectForKey:UIKeyboardAnimationCurveUserInfoKey];
        [curveValue getValue:curve];
        id durationValue = [notification.userInfo
                            objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [durationValue getValue:duration];
    } else {
        *curve = UIViewAnimationCurveEaseInOut;
        *duration = 0.3;
    }
}

- (void) keyboardWillShow:(NSNotification *)notification {
    CGRect bounds;
    CGPoint center;
    [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&bounds];
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&center];
    
    NSTimeInterval duration;
    UIViewAnimationCurve curve;
    [self getKeyboardCurve:&curve duration:&duration forNotification:notification];
    
    CGRect kbframe = CGRectMake(Retina(center.x - bounds.size.width / 2), Retina(center.y - bounds.size.height / 2), bounds.size.width, bounds.size.height);
    UIViewController *base = self;
    while ([base parentOrPresentingViewController] != nil)
        base = [base parentOrPresentingViewController];
    CGRect viewframe = [[base view] convertRect:[list_ frame] fromView:[list_ superview]];
    CGRect intersection = CGRectIntersection(viewframe, kbframe);
    
    if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iPhoneOS_3_0) // XXX: _UIApplicationLinkedOnOrAfter(4)
        intersection.size.height += CYStatusBarHeight();
    
    [self resizeForKeyboardBounds:intersection duration:duration curve:curve];
}

- (void) keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration;
    UIViewAnimationCurve curve;
    [self getKeyboardCurve:&curve duration:&duration forNotification:notification];
    
    [self resizeForKeyboardBounds:CGRectZero duration:duration curve:curve];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self resizeForKeyboardBounds:CGRectZero];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self resizeForKeyboardBounds:CGRectZero];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self deselectWithAnimation:animated];
}

- (void) didSelectPackage:(Package *)package {
    CYPackageController *view([[[CYPackageController alloc] initWithDatabase:database_ forPackage:[package id] withReferrer:[[self referrerURL] absoluteString]] autorelease]);
    [view setDelegate:delegate_];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        // some actions needed after showing tweak page triggered by swipe actions
        SwipeActionController *SAC([SwipeActionController sharedInstance]);
        if ([SAC autoClickDowngrade]) {
            [view _clickButtonWithName:@"DOWNGRADE"];
            [SAC setAutoClickDowngrade:NO];
        } else if ([SAC autoClickBuy]) {
            [view customButtonClicked];
            [SAC setAutoClickBuy:NO];
        }
    }];
    [[self navigationController] pushViewController:view animated:YES];
    [CATransaction commit];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)list {
    NSInteger count([sections_ count]);
    return count == 0 ? 1 : count;
}

- (NSString *) tableView:(UITableView *)list titleForHeaderInSection:(NSInteger)section {
    if ([sections_ count] == 0 || [[sections_ objectAtIndex:section] count] == 0)
        return nil;
    return [[sections_ objectAtIndex:section] name];
}

- (NSInteger) tableView:(UITableView *)list numberOfRowsInSection:(NSInteger)section {
    if ([sections_ count] == 0)
        return 0;
    return [[sections_ objectAtIndex:section] count];
}

- (Package *) packageAtIndexPath:(NSIndexPath *)path {
    @synchronized (database_) {
        if ([database_ era] != era_)
            return nil;
        
        Section *section([sections_ objectAtIndex:[path section]]);
        NSInteger row([path row]);
        Package *package;
        if (InstalledController.isFiltered) {
            NSString *packageId = [[database_ currentFavorites] objectAtIndex:([section row] + row)]; // package id which saved in userdefaults
            package = [database_ packageWithName:packageId];
        } else {
            package = [packages_ objectAtIndex:([section row] + row)];
        }
        return [[package retain] autorelease];
    }
}
    
- (UITableViewCell *) tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    PackageCell *cell((PackageCell *) [table dequeueReusableCellWithIdentifier:@"Package"]);
    if (cell == nil)
        cell = [[[PackageCell alloc] init] autorelease];
    
    Package *package([database_ packageWithName:[[self packageAtIndexPath:path] id]]);
    [cell setPackage:package asSummary:[self isSummarized]];
    
    return cell;
}

- (void) tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    Package *package([self packageAtIndexPath:path]);
    package = [database_ packageWithName:[package id]];
    [self didSelectPackage:package];
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView {
    return thumbs_;
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
                atIndex:(NSInteger)index {
    NSNumber *section = _sectionsForIndexTitles[index];
    
    return section.integerValue;
}

- (NSArray *)tableView:(UITableView *)tableView
editActionsForRowAtIndexPath:(NSIndexPath *)path {
    Package *package([self packageAtIndexPath:path]);
    // package = [database_ packageWithName:[package id]]; // do we need this?
    Cydia *delegate((Cydia *)[UIApplication sharedApplication]);
    NSMutableArray *actions([NSMutableArray array]);
    BOOL installed = ![package uninstalled];
    BOOL upgradable = [package upgradableAndEssential:NO];
    BOOL isQueue = [package mode] != nil;
    bool commercial = [package isCommercial];
    SwipeActionController *SAC([SwipeActionController sharedInstance]);
    if (installed) {
        // Uninstall action
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[SAC removeString] handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [SAC setFromSwipeAction:YES];
            [SAC setDismissAfterProgress:[SAC autoDismissWhenQueue]];
            [delegate removePackage:package];
        }];
        [actions addObject:deleteAction];
    }
    NSString *installTitle = installed ? (upgradable ? [SAC upgradeString] : [SAC reinstallString]) : (commercial ? [SAC buyString] : [SAC installString]);
    if ((!installed || [Device isPad] || [SAC shortLabel]) && !isQueue) {
        // Install or reinstall or upgrade action
        UITableViewRowAction *installAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:installTitle handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [SAC setFromSwipeAction:YES];
            [SAC setDismissAfterProgress:[SAC autoPerform] && (!commercial || (commercial && installed))];
            if (commercial && !installed) {
                [SAC setAutoClickBuy:YES];
                [self didSelectPackage:package];
            }
            else
                [delegate installPackage:package];
        }];
        installAction.backgroundColor = [UIColor systemBlueColor];
        [actions addObject:installAction];
    }
    if (installed && !isQueue) {
        // Queue reinstall action
        NSString *queueReinstallTitle = [SAC queueString:installTitle];
        UITableViewRowAction *queueReinstallAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:queueReinstallTitle handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [SAC setDismissAfterProgress:NO];
            [SAC setDismissAsQueue:[SAC autoDismissWhenQueue]];
            [SAC setFromSwipeAction:YES];
            [delegate installPackage:package];
        }];
        queueReinstallAction.backgroundColor = [UIColor orangeColor];
        [actions addObject:queueReinstallAction];
    }
    if (isQueue) {
        // Clear action
        UITableViewRowAction *clearAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"⌧" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [SAC setDismissAfterProgress:NO];
            [SAC setDismissAsQueue:Queuing_];
            [SAC setFromSwipeAction:YES];
            [delegate clearPackage:package];
        }];
        clearAction.backgroundColor = [UIColor grayColor];
        [actions addObject:clearAction];
    } else {
        // Queue install action
        NSString *queueTitle = [SAC queueString:(installed ? [SAC removeString] : installTitle)];
        UITableViewRowAction *queueAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:queueTitle handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [SAC setDismissAfterProgress:NO];
            [SAC setDismissAsQueue:[SAC autoDismissWhenQueue]];
            [SAC setFromSwipeAction:YES];
            if (installed)
                [delegate removePackage:package];
            else
                [delegate installPackage:package];
        }];
        queueAction.backgroundColor = installed ? [UIColor systemYellowColor] : [UIColor systemGreenColor];
        [actions addObject:queueAction];
    }
    if (!isQueue) {
        // Downgrade action
        NSArray *downgrades = [package downgrades];
        if (downgrades.count > 0)	{
            UITableViewRowAction *downgradeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:[SAC downgradeString] handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [SAC setDismissAfterProgress:NO];
                [SAC setDismissAsQueue:NO];
                [SAC setAutoClickDowngrade:YES];
                [SAC setFromSwipeAction:YES];
                [self didSelectPackage:package];
            }];
            downgradeAction.backgroundColor = [UIColor purpleColor];
            [actions addObject:downgradeAction];
        }
    }
    // Favorite action
    _UITableViewCellActionButton *favoritesButton = [_UITableViewCellActionButton buttonWithType:UIButtonTypeCustom];
    [favoritesButton setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    favoritesButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    favoritesButton.backgroundColor = [UIColor systemDarkGreenColor];
    UITableViewRowAction *addToFavoritesAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        [tableView setEditing:NO animated:YES];
        [database_ addPackageToFavoritesList:package];
        [list_ reloadData];
        
    }];
    [addToFavoritesAction _setButton:favoritesButton];
    addToFavoritesAction.backgroundColor = [UIColor systemDarkGreenColor];
    [actions addObject:addToFavoritesAction];
    return actions;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView setEditing:NO animated:YES];
}

- (void) updateHeight {
    [list_ setRowHeight:([self isSummarized] ? 38 : 73)];
}

- (id) initWithDatabase:(Database *)database title:(NSString *)title {
    if ((self = [super init]) != nil) {
        database_ = database;
        title_ = [title copy];
        [[self navigationItem] setTitle:title_];
    } return self;
}

- (void) loadView {
    UIView *view([[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]);
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self setView:view];
    
    list_ = [[[UITableView alloc] initWithFrame:[[self view] bounds] style:UITableViewStylePlain] autorelease];
    [list_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [view addSubview:list_];
    
    // XXX: is 20 the most optimal number here?
    [list_ setSectionIndexMinimumDisplayRowCount:20];
    
    [(UITableView *) list_ setDataSource:self];
    [list_ setDelegate:self];
    
    [self updateHeight];
}

- (void) releaseSubviews {
    list_ = nil;
    
    packages_ = nil;
    sections_ = nil;
    
    thumbs_ = nil;
    _sectionsForIndexTitles = nil;
    
    [super releaseSubviews];
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
}

- (bool) shouldYield {
    return false;
}

- (bool) shouldBlock {
    return false;
}

- (NSMutableArray *) _reloadPackages {
    @synchronized (database_) {
        era_ = [database_ era];
        NSArray *packages([database_ packages]);
        
        return [NSMutableArray arrayWithArray:packages];
    }
}

- (void) _reloadData {
    if (reloading_ != 0) {
        reloading_ = 2;
        return;
    }
    
    NSMutableArray *packages;
    
reload:
    if ([self shouldYield]) {
        do {
            UIProgressHUD *hud;
            
            if (![self shouldBlock])
                hud = nil;
            else {
                hud = [delegate_ addProgressHUD];
                [hud setText:UCLocalize("LOADING")];
            }
            
            reloading_ = 1;
            packages = [self yieldToSelector:@selector(_reloadPackages)];
            
            if (hud != nil)
                [delegate_ removeProgressHUD:hud];
        } while (reloading_ == 2);
    } else {
        packages = [self _reloadPackages];
    }
    
    @synchronized (database_) {
        if (era_ != [database_ era])
            goto reload;
        reloading_ = 0;
        
        thumbs_ = nil;
        _sectionsForIndexTitles = nil;
        
        packages_ = packages;
        
        if ([self showsSections])
            sections_ = [self sectionsForPackages:packages];
        else {
            Section *section([[[Section alloc] initWithName:nil row:0 localize:NO] autorelease]);
            [section setCount:[packages_ count]];
            sections_ = [NSArray arrayWithObject:section];
        }
        
        [self updateHeight];
        
        _profile(PackageTable$reloadData$List)
        [(UITableView *) list_ setDataSource:self];
        [list_ reloadData];
        _end
    }
    
    PrintTimes();
}

- (NSArray *) sectionsForPackages:(NSMutableArray *)packages {
    Section *prefix([[[Section alloc] initWithName:nil row:0 localize:NO] autorelease]);
    size_t end([packages count]);
    
    NSMutableArray *sections([NSMutableArray arrayWithCapacity:16]);
    Section *section(prefix);
    
    thumbs_ = LMXLocalizedTableSections.collationTableIndexTitles;
    _sectionsForIndexTitles = [LMXLocalizedTableSections sectionsForIndexTitles];
    
    NSArray *sectionStartStrings = LMXLocalizedTableSections.sectionStartStrings;
    size_t offset(0);
    size_t offsets = [sectionStartStrings count];
    
    NSString *start([sectionStartStrings objectAtIndex:offset]);
    size_t length([start length]);
    
    NSArray *sectionTitles = LMXLocalizedTableSections.sectionTitles;
    for (size_t index(0); index != end; ++index) {
        if (start != nil) {
            Package *package([packages objectAtIndex:index]);
            NSString *name(PackageName(package, @selector(cyname)));
            
            //while ([start compare:name options:NSNumericSearch range:NSMakeRange(0, length) locale:CollationLocale_] != NSOrderedDescending) {
            while (StringNameCompare(start, name, length) != kCFCompareGreaterThan) {
                NSString *title = [sectionTitles objectAtIndex:offset];
                section = [[[Section alloc] initWithName:title row:index localize:NO] autorelease];
                [sections addObject:section];
                
                start = ++offset == offsets ? nil : [sectionStartStrings objectAtIndex:offset];
                if (start == nil)
                    break;
                length = [start length];
            }
        }
        
        [section addToCount];
    }
    
    for (; offset != offsets; ++offset) {
        NSString *title = [sectionTitles objectAtIndex:offset];
        Section *section([[[Section alloc] initWithName:title row:end localize:NO] autorelease]);
        [sections addObject:section];
    }
    
    if ([prefix count] != 0) {
        Section *suffix([sections lastObject]);
        [prefix setName:[suffix name]];
        [suffix setName:nil];
        [sections insertObject:prefix atIndex:(offsets - 1)];
    }
    
    return sections;
}

- (void) reloadData {
    [super reloadData];
    
    if ([self shouldYield])
        [self performSelector:@selector(_reloadData) withObject:nil afterDelay:0];
    else
        [self _reloadData];
}

- (void) resetCursor {
    [list_ scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void) clearData {
    [self updateHeight];
    
    [list_ setDataSource:nil];
    [list_ reloadData];
    
    [self resetCursor];
}

#pragma mark - 3D touch
- (void)viewDidLoad{
    [super viewDidLoad];
    if ([self isForceTouchAvailable]) {
        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
}
- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}
- (UIViewController *)previewingContext:(id )previewingContext viewControllerForLocation:(CGPoint)location{
    if ([self.presentedViewController isKindOfClass:[CYPackageController class]]) {
        return nil;
    }
    
    CGPoint cellPostion = [list_ convertPoint:location fromView:self.view];
    NSIndexPath *path = [list_ indexPathForRowAtPoint:cellPostion];
    
    if (path) {
        Package *package([self packageAtIndexPath:path]);
        package = [database_ packageWithName:[package id]];
        CYPackageController *view([[[CYPackageController alloc] initWithDatabase:database_ forPackage:[package id] withReferrer:[[self referrerURL] absoluteString]] autorelease]);
        [view setDelegate:delegate_];
        return view;
    }
    return nil;
}
- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

@end
