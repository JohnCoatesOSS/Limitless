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
    if (&UIKeyboardAnimationCurveUserInfoKey == NULL)
        *curve = UIViewAnimationCurveEaseInOut;
    else
        [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:curve];
    
    if (&UIKeyboardAnimationDurationUserInfoKey == NULL)
        *duration = 0.3;
    else
        [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:duration];
}

- (void) keyboardWillShow:(NSNotification *)notification {
    CGRect bounds;
    CGPoint center;
    [[[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&bounds];
    [[[notification userInfo] objectForKey:UIKeyboardCenterEndUserInfoKey] getValue:&center];
    
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
    [[self navigationController] pushViewController:view animated:YES];
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
        Package *package([packages_ objectAtIndex:([section row] + row)]);
        return [[package retain] autorelease];
    } }

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

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return offset_[index];
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
    offset_.clear();
    
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
    } }

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
        offset_.clear();
        
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
    
    thumbs_ = CollationThumbs_;
    offset_ = CollationOffset_;
    
    size_t offset(0);
    size_t offsets([CollationStarts_ count]);
    
    NSString *start([CollationStarts_ objectAtIndex:offset]);
    size_t length([start length]);
    
    for (size_t index(0); index != end; ++index) {
        if (start != nil) {
            Package *package([packages objectAtIndex:index]);
            NSString *name(PackageName(package, @selector(cyname)));
            
            //while ([start compare:name options:NSNumericSearch range:NSMakeRange(0, length) locale:CollationLocale_] != NSOrderedDescending) {
            while (StringNameCompare(start, name, length) != kCFCompareGreaterThan) {
                NSString *title([CollationTitles_ objectAtIndex:offset]);
                section = [[[Section alloc] initWithName:title row:index localize:NO] autorelease];
                [sections addObject:section];
                
                start = ++offset == offsets ? nil : [CollationStarts_ objectAtIndex:offset];
                if (start == nil)
                    break;
                length = [start length];
            }
        }
        
        [section addToCount];
    }
    
    for (; offset != offsets; ++offset) {
        NSString *title([CollationTitles_ objectAtIndex:offset]);
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

@end