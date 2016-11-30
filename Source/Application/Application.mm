//
//  Application.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import <spawn.h>

#import "iPhonePrivate.h"
#import "System.h"
#import "Application.h"
#import "Flags.h"
#import "Networking.h"
#import "Profiling.hpp"
#import "Paths.h"
#import "CYURLCache.h"
#import "CydiaWebViewController.h"
#import "CydiaURLProtocol.h"
#import "Menes/Menes.h"
#import "AppCacheController.h"
#import "GeneralHelpers.h"
#import "StashController.h"
#import "Database.h"
#import "ProgressEvent.h"
#import "ProgressController.h"
#import "CydiaTabBarController.h"
#import "Defines.h"
#import "LoadingViewController.h"
#import "SourcesController.h"
#import "HomeController.h"
#import "SectionsController.h"
#import "ChangesController.h"
#import "InstalledController.h"
#import "SearchController.h"
#import "PackageSettingsController.h"
#import "SectionController.h"
#import "FileTable.h"
#import "DisplayHelpers.hpp"
#import "CYPackageController.h"
#import "ConfirmationController.h"

@interface Application () {
    _H<UIWindow> window_;
    _H<CydiaTabBarController> tabbar_;
    _H<CyteTabBarController> emulated_;
    
    _H<NSMutableArray> essential_;
    _H<NSMutableArray> broken_;
    
    _H<AppCacheController> appcache_;
    
    _H<NSURL> starturl_;
    
    unsigned locked_;
    unsigned activity_;
    bool loaded_;
    
    _H<StashController> stash_;
    Database *database_;
}

@end

@implementation Application

- (instancetype)init {
    self = [super init];

    if (self) {

    }

    return self;
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"didFinishLaunching");
    _trace();
    [self setApplicationShakeSupport];
    [self setUpHostConfiguration];
    [self setSharedURLCache];
    [CydiaWebViewController _initialize];
    [NSURLProtocol registerClass:[CydiaURLProtocol class]];
    [self setUpTheme];
    [self setUpPackageLists];
    [self setUpAppCache];
    if (![Device isSimulator]) {
        [self stashDirectories];
    }
    [self setUpDatabase];
    [self setUpWindow];
	[self setUpViewControllers];
	[self setUpNavigationControllerAndTabBar];
	
	// - Homescreen Shortcut Start
	
	// If the app was opened from a shortcut
	if (launchOptions[UIApplicationLaunchOptionsShortcutItemKey] != nil) {
		// Handle it
		UIApplicationShortcutItem *shortcutItem = (UIApplicationShortcutItem*)launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
		
		if ([shortcutItem.type isEqualToString:@"respring"]) {
			[self reloadSpringBoard];
		} else if ([shortcutItem.type isEqualToString:@"safemode"]) {
			[self enterSafeMode];
			
		// -(void)loadData has some pretty weird behaviour, so I have some code which sets the selectedIndex to 1 (sources), then have a function which selects the appropriate source based on the URL. Chances of URL conflict should be none.
		} else if ([shortcutItem.type isEqualToString:@"repo1"] || [shortcutItem.type isEqualToString:@"repo2"]) {
			travelToRepo = YES;
			repoURL = (NSString*)shortcutItem.userInfo[@"repoURL"];
		}
	}
	
	// If the shortcuts haven't been set before
	if (application.shortcutItems.count == 0) {
		UIMutableApplicationShortcutItem* firstRepo = [[UIMutableApplicationShortcutItem alloc] initWithType:@"repo1" localizedTitle:@"Cydia/Telesphoreo" localizedSubtitle:nil icon:nil userInfo:@{@"repoURL": @"http://apt.saurik.com/"}];
		UIMutableApplicationShortcutItem* secondRepo = [[UIMutableApplicationShortcutItem alloc] initWithType:@"repo2" localizedTitle:@"BigBoss" localizedSubtitle:nil icon:nil userInfo:@{@"repoURL": @"http://apt.thebigboss.org/repofiles/cydia/"}];
			application.shortcutItems = @[firstRepo, secondRepo];
	}
	
	// - Homescreen Shortcut End
	
    [self performSelector:@selector(loadData) withObject:nil afterDelay:0];
    _trace();
	
	return YES;
}

- (void) applicationWillSuspend {
    [database_ clean];
    [super applicationWillSuspend];
}

- (void) suspendReturningToLastApp:(BOOL)returning {
    if ([self isSafeToSuspend])
        [super suspendReturningToLastApp:returning];
}

- (void) suspend {
    if ([self isSafeToSuspend])
        [super suspend];
}

- (void) applicationSuspend {
    if ([self isSafeToSuspend])
        [super applicationSuspend];
}

- (void) applicationSuspend:(__GSEvent *)event {
    if ([self isSafeToSuspend])
        [super applicationSuspend:event];
}

- (void) _animateSuspension:(BOOL)arg0 duration:(double)arg1 startTime:(double)arg2 scale:(float)arg3 {
    if ([self isSafeToSuspend])
        [super _animateSuspension:arg0 duration:arg1 startTime:arg2 scale:arg3];
}

- (void) _setSuspended:(BOOL)value {
    if ([self isSafeToSuspend])
        [super _setSuspended:value];
}

- (void) applicationWillResignActive:(UIApplication *)application {
    // Stop refreshing if you get a phone call or lock the device.
    if ([tabbar_ updating])
        [tabbar_ cancelUpdate];
    
    if ([[self superclass] instancesRespondToSelector:@selector(applicationWillResignActive:)])
        [super applicationWillResignActive:application];
}


- (void) applicationWillTerminate:(UIApplication *)application {
    [self saveState];
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
    if (kCFCoreFoundationVersionNumber < 1000 && [self isSafeToSuspend])
        return [self terminateWithSuccess];
    Backgrounded_ = [NSDate date];
    [self saveState];
}

- (void) applicationWillEnterForeground:(UIApplication *)application {
    if (Backgrounded_ == nil)
        return;
    
    NSTimeInterval interval([Backgrounded_ timeIntervalSinceNow]);
    
    if (interval <= -(30*60)) {
        [tabbar_ setSelectedIndex:0];
        [[[tabbar_ viewControllers] objectAtIndex:0] popToRootViewControllerAnimated:NO];
    }
    
    if (interval <= -(15*60)) {
        if (IsReachable("cydia.saurik.com")) {
            [tabbar_ beginUpdate];
            [appcache_ reloadURLWithCache:YES];
        }
    }
    
    if ([database_ delocked])
        [self reloadData];
}

#pragma mark - State

- (void) saveState {
    [[NSDictionary dictionaryWithObjectsAndKeys:
      @"InterfaceState", [tabbar_ navigationURLCollection],
      @"LastClosed", [NSDate date],
      @"InterfaceIndex", [NSNumber numberWithInt:[tabbar_ selectedIndex]],
      nil] writeToFile:[Paths savedState] atomically:YES];
    
    [self _saveConfig];
}



- (BOOL) isSafeToSuspend {
    if (locked_ != 0) {
#if !ForRelease
        NSLog(@"isSafeToSuspend: locked_ != 0");
#endif
        return false;
    }
    
    if ([tabbar_ modalViewController] != nil)
        return false;
    
    // Use external process status API internally.
    // This is probably a really bad idea.
    // XXX: what is the point of this? does this solve anything at all?
    uint64_t status = 0;
    int notify_token;
    if (notify_register_check("com.saurik.Cydia.status", &notify_token) == NOTIFY_STATUS_OK) {
        notify_get_state(notify_token, &status);
        notify_cancel(notify_token);
    }
    
    if (status != 0) {
#if !ForRelease
        NSLog(@"isSafeToSuspend: status != 0");
#endif
        return false;
    }
    
#if !ForRelease
    NSLog(@"isSafeToSuspend: -> true");
#endif
    return true;
}



#pragma mark - Startup

- (void)setApplicationShakeSupport {
    if ([self respondsToSelector:@selector(setApplicationSupportsShakeToEdit:)]) {
        [self setApplicationSupportsShakeToEdit:NO];
    }
}
- (void)setUpHostConfiguration {
    @synchronized (HostConfig_) {
        [BridgedHosts_ addObject:[[NSURL URLWithString:CydiaURL(@"")] host]];
    }
}

- (void)setSharedURLCache {
    CYURLCache *sharedURLCache = [[[CYURLCache alloc]
                                   initWithMemoryCapacity:524288
                                   diskCapacity:10485760
                                   diskPath:[Paths cacheFile:@"SDURLCache"]]
                                  autorelease];
    [NSURLCache setSharedURLCache:sharedURLCache];
}

- (void)setUpTheme {
    Font12_ = [UIFont systemFontOfSize:12];
    Font12Bold_ = [UIFont boldSystemFontOfSize:12];
    Font14_ = [UIFont systemFontOfSize:14];
    Font18_ = [UIFont systemFontOfSize:18];
    Font18Bold_ = [UIFont boldSystemFontOfSize:18];
    Font22Bold_ = [UIFont boldSystemFontOfSize:22];
}

- (void)setUpPackageLists {
    essential_ = [NSMutableArray arrayWithCapacity:4];
    broken_ = [NSMutableArray arrayWithCapacity:4];
}

- (void)setUpAppCache {
    // XXX: I really need this thing... like, seriously... I'm sorry
    appcache_ = [[[AppCacheController alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/appcache/", UI_]]] autorelease];
    [appcache_ reloadData];
}

- (void)setUpWindow {
    window_ = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [window_ orderFront:self];
    [window_ makeKey:self];
    [window_ setHidden:NO];
    [window_ setUserInteractionEnabled:NO];
}

- (void)setUpDatabase {
    database_ = [Database sharedInstance];
    [database_ setDelegate:self];
}

- (void)setUpViewControllers {
     tabbar_ = [[[CydiaTabBarController alloc] initWithDatabase:database_]
                autorelease];
    
    NSMutableArray *items;
    if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0) {
        items = [NSMutableArray arrayWithObjects:
                 [[[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"home.png"] tag:0] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("SOURCES") image:[UIImage imageNamed:@"install.png"] tag:0] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("CHANGES") image:[UIImage imageNamed:@"changes.png"] tag:0] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("INSTALLED") image:[UIImage imageNamed:@"manage.png"] tag:0] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("SEARCH") image:[UIImage imageNamed:@"search.png"] tag:0] autorelease],
                 nil];
    } else {
        items = [NSMutableArray arrayWithObjects:
                 [[[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"home7.png"] selectedImage:[UIImage imageNamed:@"home7s.png"]] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("SOURCES") image:[UIImage imageNamed:@"install7.png"] selectedImage:[UIImage imageNamed:@"install7s.png"]] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("CHANGES") image:[UIImage imageNamed:@"changes7.png"] selectedImage:[UIImage imageNamed:@"changes7s.png"]] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("INSTALLED") image:[UIImage imageNamed:@"manage7.png"] selectedImage:[UIImage imageNamed:@"manage7s.png"]] autorelease],
                 [[[UITabBarItem alloc] initWithTitle:UCLocalize("SEARCH") image:[UIImage imageNamed:@"search7.png"] selectedImage:[UIImage imageNamed:@"search7s.png"]] autorelease],
                 nil];
    }
    
    NSMutableArray *controllers([NSMutableArray array]);
    for (UITabBarItem *item in items) {
        UINavigationController *controller([[[UINavigationController alloc] init] autorelease]);
        [controller setTabBarItem:item];
        [controllers addObject:controller];
    }
    [tabbar_ setViewControllers:controllers];
    
    [tabbar_ setUpdateDelegate:self];

}

- (void)setUpNavigationControllerAndTabBar {
    CydiaLoadingViewController *loading([[[CydiaLoadingViewController alloc] init] autorelease]);
    UINavigationController *navigation([[[UINavigationController alloc] init] autorelease]);
    [navigation setViewControllers:[NSArray arrayWithObject:loading]];
    
    emulated_ = [[[CyteTabBarController alloc] init] autorelease];
    [emulated_ setViewControllers:[NSArray arrayWithObject:navigation]];
    [emulated_ setSelectedIndex:0];
    
    if ([emulated_ respondsToSelector:@selector(concealTabBarSelection)])
        [emulated_ concealTabBarSelection];
    
    if ([window_ respondsToSelector:@selector(setRootViewController:)])
        [window_ setRootViewController:emulated_];
    else
        [window_ addSubview:[emulated_ view]];
    
}
#pragma mark - Stashing

- (void)stashDirectories {
    if (access("/.cydia_no_stash", F_OK) == 0);
    else {
        
        if (false) stash: {
            [self addStashController];
            // XXX: this would be much cleaner as a yieldToSelector:
            // that way the removeStashController could happen right here inline
            // we also could no longer require the useless stash_ field anymore
            [self performSelector:@selector(stash) withObject:nil afterDelay:0];
            return;
        }
        
        struct stat root;
        int error(stat("/", &root));
        _assert(error != -1);
        
#define Stash_(path) do { \
struct stat folder; \
int error(lstat((path), &folder)); \
if (error != -1 && ( \
folder.st_dev == root.st_dev && \
S_ISDIR(folder.st_mode) \
) || error == -1 && ( \
errno == ENOENT || \
errno == ENOTDIR \
)) goto stash; \
} while (false)
        
        Stash_("/Applications");
        Stash_("/Library/Ringtones");
        Stash_("/Library/Wallpaper");
        //Stash_("/usr/bin");
        Stash_("/usr/include");
        Stash_("/usr/share");
        //Stash_("/var/lib");
        
    }
}

- (void) addStashController {
    [self lockSuspend];
    stash_ = [[[StashController alloc] init] autorelease];
    [window_ addSubview:[stash_ view]];
}

- (void) removeStashController {
    [[stash_ view] removeFromSuperview];
    stash_ = nil;
    [self unlockSuspend];
}

- (void) stash {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    UpdateExternalStatus(1);
    [self yieldToSelector:@selector(system:)
               withObject:@"/Applications/Limitless.app/runAsSuperuser /usr/libexec/cydia/free.sh"];
    UpdateExternalStatus(0);
    
    [self removeStashController];
    [self reloadSpringBoard];
}

#pragma mark - Handling Suspension

- (void) lockSuspend {
    if (locked_++ == 0) {
        if ($SBSSetInterceptsMenuButtonForever != NULL)
            (*$SBSSetInterceptsMenuButtonForever)(true);
        
        [self setIdleTimerDisabled:YES];
    }
}

- (void) unlockSuspend {
    if (--locked_ == 0) {
        [self setIdleTimerDisabled:NO];
        
        if ($SBSSetInterceptsMenuButtonForever != NULL)
            (*$SBSSetInterceptsMenuButtonForever)(false);
    }
}

#pragma mark - Database Delegate

- (void) repairWithSelector:(SEL)selector {
    NSInvocation *invocation = [NSInvocation invocationWithSelector:selector
                                                          forTarget:database_];
    [self performSelectorOnMainThread:@selector(repairWithInvocation:)
                           withObject:invocation waitUntilDone:YES];
}

- (void) repairWithInvocation:(NSInvocation *)invocation {
    _trace();
    [self invokeNewProgress:invocation
              forController:nil
                  withTitle:@"REPAIRING"];
    _trace();
}

- (void) setConfigurationData:(NSString *)data {
    static RegEx conffile_r("'(.*)' '(.*)' ([01]) ([01])");
    
    if (!conffile_r(data)) {
        lprintf("E:invalid conffile\n");
        return;
    }
    
    NSString *ofile = conffile_r[1];
    //NSString *nfile = conffile_r[2];
    
    UIAlertView *alert = [[[UIAlertView alloc]
                           initWithTitle:UCLocalize("CONFIGURATION_UPGRADE")
                           message:[NSString stringWithFormat:@"%@\n\n%@", UCLocalize("CONFIGURATION_UPGRADE_EX"), ofile]
                           delegate:self
                           cancelButtonTitle:UCLocalize("KEEP_OLD_COPY")
                           otherButtonTitles:
                           UCLocalize("ACCEPT_NEW_COPY"),
                           // XXX: UCLocalize("SEE_WHAT_CHANGED"),
                           nil
                           ] autorelease];
    
    [alert setContext:@"conffile"];
    [alert setNumberOfRows:2];
    [alert show];
}

- (void) loadData {
    _trace();
    if ([emulated_ modalViewController] != nil)
        [emulated_ dismissModalViewControllerAnimated:YES];
    [window_ setUserInteractionEnabled:NO];
    
    [self reloadDataWithInvocation: nil];
    [self refreshIfPossible];
    [self disemulate];
    
    NSDictionary *state([NSDictionary dictionaryWithContentsOfFile:[Paths savedState]]);
    
    int savedIndex = [[state objectForKey:@"InterfaceIndex"] intValue];
    NSArray *saved = [[[state objectForKey:@"InterfaceState"] mutableCopy] autorelease];
    NSArray *standard = [self defaultStartPages];
	int standardIndex(0);
	
    BOOL valid = YES;
    
    if (saved == nil)
        valid = NO;
    
    NSDate *closed = [state objectForKey:@"LastClosed"];
    if (valid && closed != nil) {
        NSTimeInterval interval([closed timeIntervalSinceNow]);
        if (interval <= -(30*60))
            valid = NO;
    }
    
    if (valid && [saved count] != [standard count])
        valid = NO;
    
    if (valid) {
        for (unsigned int i = 0; i < [standard count]; i++) {
            NSArray *std = [standard objectAtIndex:i], *sav = [saved objectAtIndex:i];
            // XXX: The "hasPrefix" sanity check here could be, in theory, fooled,
            //      but it's good enough for now.
            if ([sav count] == 0 || ![[sav objectAtIndex:0] hasPrefix:[std objectAtIndex:0]]) {
                valid = NO;
                break;
            }
        }
    }
    
    NSArray *items = nil;
	
	// If we need to go to the sources page, override what has been set before
	if (travelToRepo) {
		savedIndex = 1;
		standardIndex = 1;
	}

    if (valid) {
        [tabbar_ setSelectedIndex:savedIndex];
        items = saved;
    } else {
        [tabbar_ setSelectedIndex:standardIndex];
        items = standard;
    }
    
    for (unsigned int tab = 0; tab < [[tabbar_ viewControllers] count]; tab++) {
        NSArray *stack = [items objectAtIndex:tab];
        UINavigationController *navigation = [[tabbar_ viewControllers] objectAtIndex:tab];
        NSMutableArray *current = [NSMutableArray array];
        
        for (unsigned int nav = 0; nav < [stack count]; nav++) {
            NSString *addr = [stack objectAtIndex:nav];
            NSURL *url = [NSURL URLWithString:addr];
            CyteViewController *page = [self pageForURL:url forExternal:NO withReferrer:nil];
            if (page != nil)
                [current addObject:page];
        }
        
        [navigation setViewControllers:current];
    }
	
	// Get the sources controller, and call our function to select it when the VC + database loads
	if (travelToRepo && ![repoURL isEqualToString:@""]) {
		SourcesController *sVC = (SourcesController*)[[tabbar_ viewControllers] objectAtIndex:1].childViewControllers[0];
		[sVC selectSourceWithURL:repoURL];
		repoURL = @"";
		travelToRepo = NO;
	}
	
    // (Try to) show the startup URL.
    if (starturl_ != nil) {
        [self openCydiaURL:starturl_ forExternal:YES];
        starturl_ = nil;
    }
}

- (void) reloadDataWithInvocation:(NSInvocation *)invocation {
    _profile(reloadDataWithInvocation)
    @synchronized (self) {
        UIProgressHUD *hud(loaded_ ? [self addProgressHUD] : nil);
        if (hud != nil)
            [hud setText:UCLocalize("RELOADING_DATA")];
        
        [database_ yieldToSelector:@selector(reloadDataWithInvocation:) withObject:invocation];
        
        size_t changes(0);
        
        [essential_ removeAllObjects];
        [broken_ removeAllObjects];
        
        _profile(reloadDataWithInvocation$Essential)
        NSArray *packages([database_ packages]);
        for (Package *package in packages) {
            if ([package half])
                [broken_ addObject:package];
            if ([package upgradableAndEssential:YES] && ![package ignored]) {
                if ([package essential] && [package installed] != nil)
                    [essential_ addObject:package];
                ++changes;
            }
        }
        _end
        
        UITabBarItem *changesItem = [[[tabbar_ viewControllers] objectAtIndex:2] tabBarItem];
        if (changes != 0) {
            _trace();
            NSString *badge([[NSNumber numberWithInt:changes] stringValue]);
            [changesItem setBadgeValue:badge];
            [changesItem setAnimatedBadge:([essential_ count] > 0)];
            [self setApplicationIconBadgeNumber:changes];
        } else {
            _trace();
            [changesItem setBadgeValue:nil];
            [changesItem setAnimatedBadge:NO];
            [self setApplicationIconBadgeNumber:0];
        }
        
        Queuing_ = false;
        [self _updateData];
        
        if (hud != nil)
            [self removeProgressHUD:hud];
    }
    _end
    
    PrintTimes();
}


- (void) refreshIfPossible {
    [NSThread detachNewThreadSelector:@selector(_refreshIfPossible)
                             toTarget:self
                           withObject:nil];
}

- (void) _refreshIfPossible {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDate *update([[NSDictionary dictionaryWithContentsOfFile:[Paths cacheState]] objectForKey:@"LastUpdate"]);
    
    bool recently = false;
    if (update != nil) {
        NSTimeInterval interval([update timeIntervalSinceNow]);
        if (interval > -(15*60))
            recently = true;
    }
    
    // Don't automatic refresh if:
    //  - We already refreshed recently.
    //  - We already auto-refreshed this launch.
    //  - Auto-refresh is disabled.
    //  - Cydia's server is not reachable
    if (recently || loaded_ || ManualRefresh || !IsReachable("cydia.saurik.com")) {
        // If we are cancelling, we need to make sure it knows it's already loaded.
        loaded_ = true;
        
        [self performSelectorOnMainThread:@selector(_loaded) withObject:nil waitUntilDone:NO];
    } else {
        // We are going to load, so remember that.
        loaded_ = true;
        
        [tabbar_ performSelectorOnMainThread:@selector(beginUpdate) withObject:nil waitUntilDone:NO];
    }
    
    [pool release];
}

#pragma mark - Progress

- (ProgressController *) invokeNewProgress:(NSInvocation *)invocation
                             forController:(UINavigationController *)navigation
                                 withTitle:(NSString *)title {
    ProgressController *progress = [[[ProgressController alloc] initWithDatabase:database_
                                                                        delegate:self]
                                    autorelease];
    
    if (navigation != nil) {
        [navigation pushViewController:progress animated:YES];
    } else {
        [self presentModalViewController:progress force:YES];
    }
    
    [progress invoke:invocation withTitle:title];
    return progress;
}

- (void) detachNewProgressSelector:(SEL)selector
                          toTarget:(id)target forController:(UINavigationController *)navigation
                             title:(NSString *)title {
    NSInvocation *invocation = [NSInvocation invocationWithSelector:selector
                                                          forTarget:target];
    [self invokeNewProgress:invocation
              forController:navigation
                  withTitle:title];
}

- (void) addProgressEventOnMainThread:(CydiaProgressEvent *)event
                              forTask:(NSString *)task {
    [self performSelectorOnMainThread:@selector(addProgressEventForTask:)
                           withObject:@[event, task]
                        waitUntilDone:YES];
}

- (void) addProgressEventForTask:(NSArray *)data {
    CydiaProgressEvent *event([data objectAtIndex:0]);
    NSString *task([data count] < 2 ? nil : [data objectAtIndex:1]);
    [self addProgressEvent:event forTask:task];
}


- (void) addProgressEvent:(CydiaProgressEvent *)event
                  forTask:(NSString *)task {
    id<ProgressDelegate> progress([database_ progressDelegate] ?: [self invokeNewProgress:nil forController:nil withTitle:task]);
    [progress setTitle:task];
    [progress addProgressEvent:event];
}

#pragma mark - View Controllers

- (void) presentModalViewController:(UIViewController *)controller
                              force:(BOOL)force {
    UINavigationController *navigation = [[[UINavigationController alloc]
                                           initWithRootViewController:controller]
                                          autorelease];
    
    UIViewController *parent;
    if (emulated_ == nil)
        parent = tabbar_;
    else if (!force)
        parent = emulated_;
    else {
        [self disemulate];
        parent = tabbar_;
    }
    
    if ([Device isPad])
        [navigation setModalPresentationStyle:UIModalPresentationFormSheet];
    [parent presentModalViewController:navigation animated:YES];
}

- (void) disemulate {
    if (emulated_ == nil)
        return;
    
    if ([window_ respondsToSelector:@selector(setRootViewController:)])
        [window_ setRootViewController:tabbar_];
    else {
        [window_ addSubview:[tabbar_ view]];
        [[emulated_ view] removeFromSuperview];
    }
    
    emulated_ = nil;
    [window_ setUserInteractionEnabled:YES];
}

#pragma mark - Configuration

- (NSArray *) defaultStartPages {
    NSMutableArray *standard = [NSMutableArray array];
    [standard addObject:[NSArray arrayWithObject:@"cydia://home"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://sources"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://changes"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://installed"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://search"]];
    return standard;
}

#pragma mark - URL Handling

- (CyteViewController *) pageForURL:(NSURL *)url forExternal:(BOOL)external withReferrer:(NSString *)referrer {
    NSString *scheme([[url scheme] lowercaseString]);
    if ([[url absoluteString] length] <= [scheme length] + 3)
        return nil;
    NSString *path([[url absoluteString] substringFromIndex:[scheme length] + 3]);
    NSArray *components([path componentsSeparatedByString:@"/"]);
    
    if ([scheme isEqualToString:@"apptapp"] && [components count] > 0 && [[components objectAtIndex:0] isEqualToString:@"package"]) {
        CyteViewController *controller([self pageForPackage:[components objectAtIndex:1] withReferrer:referrer]);
        if (controller != nil)
            [controller setDelegate:self];
        return controller;
    }
    
    if ([components count] < 1 || ![scheme isEqualToString:@"cydia"])
        return nil;
    
    NSString *base([components objectAtIndex:0]);
    
    CyteViewController *controller = nil;
    
    if ([base isEqualToString:@"url"]) {
        // This kind of URL can contain slashes in the argument, so we can't parse them below.
        NSString *destination = [[url absoluteString] substringFromIndex:([scheme length] + [@"://" length] + [base length] + [@"/" length])];
        controller = [[[CydiaWebViewController alloc] initWithURL:[NSURL URLWithString:destination]] autorelease];
    } else if (!external && [components count] == 1) {
        if ([base isEqualToString:@"sources"]) {
            controller = [[[SourcesController alloc] initWithDatabase:database_] autorelease];
        }
        
        if ([base isEqualToString:@"home"]) {
            controller = [[[HomeController alloc] init] autorelease];
        }
        
        if ([base isEqualToString:@"sections"]) {
            controller = [[[SectionsController alloc] initWithDatabase:database_ source:nil] autorelease];
        }
        
        if ([base isEqualToString:@"search"]) {
            controller = [[[SearchController alloc] initWithDatabase:database_ query:nil] autorelease];
        }
        
        if ([base isEqualToString:@"changes"]) {
            controller = [[[ChangesController alloc] initWithDatabase:database_] autorelease];
        }
        
        if ([base isEqualToString:@"installed"]) {
            controller = [[[InstalledController alloc] initWithDatabase:database_] autorelease];
        }
    } else if ([components count] == 2) {
        NSString *argument = [[components objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([base isEqualToString:@"package"]) {
            controller = [self pageForPackage:argument withReferrer:referrer];
        }
        
        if (!external && [base isEqualToString:@"search"]) {
            controller = [[[SearchController alloc] initWithDatabase:database_ query:argument] autorelease];
        }
        
        if (!external && [base isEqualToString:@"sections"]) {
            if ([argument isEqualToString:@"all"] || [argument isEqualToString:@"*"])
                argument = nil;
            controller = [[[SectionController alloc] initWithDatabase:database_ source:nil section:argument] autorelease];
        }
        
        if ([base isEqualToString:@"sources"]) {
            if ([argument isEqualToString:@"add"]) {
                controller = [[[SourcesController alloc] initWithDatabase:database_] autorelease];
                [(SourcesController *)controller showAddSourcePrompt];
            } else {
                Source *source([database_ sourceWithKey:argument]);
                controller = [[[SectionsController alloc] initWithDatabase:database_ source:source] autorelease];
            }
        }
        
        if (!external && [base isEqualToString:@"launch"]) {
            [self launchApplicationWithIdentifier:argument suspended:NO];
            return nil;
        }
    } else if (!external && [components count] == 3) {
        NSString *arg1 = [[components objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *arg2 = [[components objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([base isEqualToString:@"package"]) {
            if ([arg2 isEqualToString:@"settings"]) {
                controller = [[[PackageSettingsController alloc] initWithDatabase:database_ package:arg1] autorelease];
            } else if ([arg2 isEqualToString:@"files"]) {
                if (Package *package = [database_ packageWithName:arg1]) {
                    controller = [[[FileTable alloc] initWithDatabase:database_] autorelease];
                    [(FileTable *)controller setPackage:package];
                }
            }
        }
        
        if ([base isEqualToString:@"sections"]) {
            Source *source([arg1 isEqualToString:@"*"] ? nil : [database_ sourceWithKey:arg1]);
            NSString *section([arg2 isEqualToString:@"*"] ? nil : arg2);
            controller = [[[SectionController alloc] initWithDatabase:database_ source:source section:section] autorelease];
        }
    }
    
    [controller setDelegate:self];
    return controller;
}

- (BOOL) openCydiaURL:(NSURL *)url forExternal:(BOOL)external {
    CyteViewController *page([self pageForURL:url forExternal:external withReferrer:nil]);
    
    if (page != nil)
        [tabbar_ setUnselectedViewController:page];
    
    return page != nil;
}

- (void) applicationOpenURL:(NSURL *)url {
    [super applicationOpenURL:url];
    
    if (!loaded_)
        starturl_ = url;
    else
        [self openCydiaURL:url forExternal:YES];
}

#pragma mark - Progress HUD

- (UIProgressHUD *) addProgressHUD {
    UIProgressHUD *hud([[[UIProgressHUD alloc] init] autorelease]);
    [hud setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    
    [window_ setUserInteractionEnabled:NO];
    
    UIViewController *target(tabbar_);
    if (UIViewController *modal = [target modalViewController])
        target = modal;
    
    [hud showInView:[target view]];
    
    [self lockSuspend];
    return hud;
}

- (void) removeProgressHUD:(UIProgressHUD *)hud {
    [self unlockSuspend];
    [hud hide];
    [hud removeFromSuperview];
    [window_ setUserInteractionEnabled:YES];
}

#pragma mark - Data

- (void) _loaded {
    if ([broken_ count] != 0) {
        int count = [broken_ count];
        
        UIAlertView *alert = [[[UIAlertView alloc]
                               initWithTitle:(count == 1 ? UCLocalize("HALFINSTALLED_PACKAGE") : [NSString stringWithFormat:UCLocalize("HALFINSTALLED_PACKAGES"), count])
                               message:UCLocalize("HALFINSTALLED_PACKAGE_EX")
                               delegate:self
                               cancelButtonTitle:[NSString stringWithFormat:UCLocalize("PARENTHETICAL"), UCLocalize("FORCIBLY_CLEAR"), UCLocalize("UNSAFE")]
                               otherButtonTitles:
                               UCLocalize("TEMPORARY_IGNORE"),
                               nil
                               ] autorelease];
        
        [alert setContext:@"fixhalf"];
        [alert setNumberOfRows:2];
        [alert show];
    } else if (!Ignored_ && [essential_ count] != 0) {
        int count = [essential_ count];
        
        UIAlertView *alert = [[[UIAlertView alloc]
                               initWithTitle:(count == 1 ? UCLocalize("ESSENTIAL_UPGRADE") : [NSString stringWithFormat:UCLocalize("ESSENTIAL_UPGRADES"), count])
                               message:UCLocalize("ESSENTIAL_UPGRADE_EX")
                               delegate:self
                               cancelButtonTitle:UCLocalize("TEMPORARY_IGNORE")
                               otherButtonTitles:
                               UCLocalize("UPGRADE_ESSENTIAL"),
                               UCLocalize("COMPLETE_UPGRADE"),
                               nil
                               ] autorelease];
        
        [alert setContext:@"upgrade"];
        [alert show];
    }
}

- (void) unloadData {
    [tabbar_ unloadData];
}

- (void) _saveConfig {
    SaveConfig(database_);
}

- (void) _updateData {
    [self _saveConfig];
    [self unloadData];
    
    UINavigationController *navigation = [self queueNavigationController];
    
    id queuedelegate = nil;
    if ([[navigation viewControllers] count] > 0)
        queuedelegate = [[navigation viewControllers] objectAtIndex:0];
    
    [queuedelegate queueStatusDidChange];
    [[navigation tabBarItem] setBadgeValue:(Queuing_ ? UCLocalize("Q_D") : nil)];
}

- (void) updateData {
    [self _updateData];
}

- (void) updateDataAndLoad {
    [self _updateData];
    if ([database_ progressDelegate] == nil)
        [self _loaded];
}

- (void) reloadData {
    [self reloadDataWithInvocation:nil];
    if ([database_ progressDelegate] == nil)
        [self _loaded];
}

- (void) update_ {
    [database_ update];
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void) syncData {
    [self _saveConfig];
    [self detachNewProgressSelector:@selector(update_)
                           toTarget:self
                      forController:nil
                              title:@"UPDATING_SOURCES"];
}

- (void) beginUpdate {
    [tabbar_ beginUpdate];
}

- (void) cancelUpdate {
    [tabbar_ cancelUpdate];
}

- (bool) requestUpdate {
    if (IsReachable("cydia.saurik.com")) {
        [self beginUpdate];
        return true;
    } else {
        UIAlertView *alert = [[[UIAlertView alloc]
                               initWithTitle:[NSString stringWithFormat:Colon_, Error_, UCLocalize("REFRESH")]
                               message:@"Host Unreachable" // XXX: Localize
                               delegate:self
                               cancelButtonTitle:UCLocalize("OK")
                               otherButtonTitles:nil
                               ] autorelease];
        
        [alert setContext:@"norefresh"];
        [alert show];
        
        return false;
    }
}

- (BOOL) updating {
    return [tabbar_ updating];
}

- (void) returnToCydia {
    [self _loaded];
}



- (void) distUpgrade {
    @synchronized (self) {
        if (![database_ upgrade])
            return;
        [self perform];
    }
}

- (void) perform_ {
    [database_ perform];
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(uicache) withObject:nil waitUntilDone:YES];
}

#pragma mark - Packages

- (CyteViewController *) pageForPackage:(NSString *)name
                           withReferrer:(NSString *)referrer {
    return [[[CYPackageController alloc] initWithDatabase:database_
                                               forPackage:name
                                             withReferrer:referrer] autorelease];
}


- (void) clearPackage:(Package *)package {
    @synchronized (self) {
        [package clear];
        [self resolve];
        [self perform];
    }
}

- (void) installPackages:(NSArray *)packages {
    @synchronized (self) {
        for (Package *package in packages)
            [package install];
        [self resolve];
        [self perform];
    }
}

- (void) installPackage:(Package *)package {
    @synchronized (self) {
        [package install];
        [self resolve];
        [self perform];
    }
}

- (void) removePackage:(Package *)package {
    @synchronized (self) {
        [package remove];
        [self resolve];
        [self perform];
    }
}

- (void) cancelAndClear:(bool)clear {
    @synchronized (self) {
        if (clear) {
            [database_ clear];
            Queuing_ = false;
        } else {
            Queuing_ = true;
        }
        
        [self _updateData];
    }
}


- (void) resolve {
    pkgProblemResolver *resolver = [database_ resolver];
    
    resolver->InstallProtect();
    if (!resolver->Resolve(true))
        _error->Discard();
}

- (bool) perform {
    // XXX: this is a really crappy way of doing this.
    // like, seriously: this state machine is still broken, and cancelling this here doesn't really /fix/ that.
    // for one, the user can still /start/ a reloading data event while they have a queue, which is stupid
    // for two, this just means there is a race condition between the refresh completing and the confirmation controller appearing.
    if ([tabbar_ updating])
        [tabbar_ cancelUpdate];
    
    if (![database_ prepare])
        return false;
    
    ConfirmationController *page([[[ConfirmationController alloc] initWithDatabase:database_] autorelease]);
    [page setDelegate:self];
    UINavigationController *confirm_([[[UINavigationController alloc] initWithRootViewController:page] autorelease]);
    
    if ([Device isPad])
        [confirm_ setModalPresentationStyle:UIModalPresentationFormSheet];
    [tabbar_ presentModalViewController:confirm_ animated:YES];
    
    return true;
}

- (void) queue {
    @synchronized (self) {
        [self perform];
    }
}


#pragma mark - Navigation

// Navigation controller for the queuing badge.
- (UINavigationController *) queueNavigationController {
    NSArray *controllers = [tabbar_ viewControllers];
    return [controllers objectAtIndex:3];
}

- (void) confirmWithNavigationController:(UINavigationController *)navigation {
    Queuing_ = false;
    [self lockSuspend];
    [self detachNewProgressSelector:@selector(perform_) toTarget:self forController:navigation title:@"RUNNING"];
    [self unlockSuspend];
}


#pragma mark - Network Activity

- (void) retainNetworkActivityIndicator {
    if (activity_++ == 0)
        [self setNetworkActivityIndicatorVisible:YES];
    
#if TraceLogging
    NSLog(@"retainNetworkActivityIndicator->%d", activity_);
#endif
}

- (void) releaseNetworkActivityIndicator {
    if (--activity_ == 0)
        [self setNetworkActivityIndicatorVisible:NO];
    
#if TraceLogging
    NSLog(@"releaseNetworkActivityIndicator->%d", activity_);
#endif
    
}

#pragma mark - Source Adding

- (void) addSource:(NSDictionary *) source {
    CydiaAddSource(source);
}

- (void) addSource:(NSString *)href withDistribution:(NSString *)distribution andSections:(NSArray *)sections {
    CydiaAddSource(href, distribution, sections);
}

// XXX: this method should not return anything
- (BOOL) addTrivialSource:(NSString *)href {
    CydiaAddSource(href, @"./");
    return YES;
}


#pragma mark - Utilities

- (void) system:(NSString *)command {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    
    _trace();
    system([command UTF8String]);
    _trace();
    
    [pool release];
}

#pragma mark - SpringBoard

- (void) reloadSpringBoard {
	if (kCFCoreFoundationVersionNumber >= 700) // XXX: iOS 6.x
		system("/bin/launchctl stop com.apple.backboardd");
	else
		system("/bin/launchctl stop com.apple.SpringBoard");
	sleep(15);
	system("/usr/bin/killall backboardd SpringBoard");
}

// Not too sure on how to implement this in the future.
- (void) enterSafeMode {
	system("/usr/bin/killall -SEGV SpringBoard");
}

- (void) _uicache {
    _trace();
    if (![Device isSimulator]) {
        system("/usr/bin/uicache");
    }
    _trace();
}

- (void) uicache {
    UIProgressHUD *hud([self addProgressHUD]);
    [hud setText:UCLocalize("LOADING")];
    [self yieldToSelector:@selector(_uicache)];
    [self removeProgressHUD:hud];
}


#pragma mark - Action Sheet

- (void) showActionSheet:(UIActionSheet *)sheet fromItem:(UIBarButtonItem *)item {
    if (![Device isPad]) {
        [sheet addButtonWithTitle:UCLocalize("CANCEL")];
        [sheet setCancelButtonIndex:[sheet numberOfButtons] - 1];
    }
    
    if (item != nil && [Device isPad]) {
        [sheet showFromBarButtonItem:item animated:YES];
    } else {
        [sheet showInView:window_];
    }
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button {
    NSString *context([alert context]);
    
    if ([context isEqualToString:@"conffile"]) {
        FILE *input = [database_ input];
        if (button == [alert cancelButtonIndex])
            fprintf(input, "N\n");
        else if (button == [alert firstOtherButtonIndex])
            fprintf(input, "Y\n");
        fflush(input);
        
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else if ([context isEqualToString:@"fixhalf"]) {
        if (button == [alert cancelButtonIndex]) {
            @synchronized (self) {
                for (Package *broken in (id) broken_) {
                    [broken remove];
                    NSString *id(ShellEscape([broken id]));
                    system([[NSString stringWithFormat:@"/Applications/Limitless.app/runAsSuperuser /bin/rm -f"
                             " /var/lib/dpkg/info/%@.prerm"
                             " /var/lib/dpkg/info/%@.postrm"
                             " /var/lib/dpkg/info/%@.preinst"
                             " /var/lib/dpkg/info/%@.postinst"
                             " /var/lib/dpkg/info/%@.extrainst_"
                             "", id, id, id, id, id] UTF8String]);
                }
                
                [self resolve];
                [self perform];
            }
        } else if (button == [alert firstOtherButtonIndex]) {
            [broken_ removeAllObjects];
            [self _loaded];
        }
        
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else if ([context isEqualToString:@"upgrade"]) {
        if (button == [alert firstOtherButtonIndex]) {
            @synchronized (self) {
                for (Package *essential in (id) essential_)
                    [essential install];
                
                [self resolve];
                [self perform];
            }
        } else if (button == [alert firstOtherButtonIndex] + 1) {
            [self distUpgrade];
        } else if (button == [alert cancelButtonIndex]) {
            Ignored_ = YES;
        }
        
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    }
}

#pragma mark - Memory Warnings

- (void) _sendMemoryWarningNotification {
    if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iPhoneOS_3_0) // XXX: maybe 4_0?
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationMemoryWarningNotification" object:[UIApplication sharedApplication]];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidReceiveMemoryWarningNotification" object:[UIApplication sharedApplication]];
}

- (void) _sendMemoryWarningNotifications {
    while (true) {
        [self performSelectorOnMainThread:@selector(_sendMemoryWarningNotification) withObject:nil waitUntilDone:NO];
        sleep(2);
        //usleep(2000000);
    }
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"--");
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark - 3D Touch

BOOL travelToRepo(false);
NSString* repoURL(@"");

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
	
	// This function is called while the app is already open. If it isn't, the shortcut handling is done in didFinishLaunchingWithOptions
	if ([shortcutItem.type isEqualToString:@"respring"]) {
		NSLog(@"Respringing through 3D Touch");
		[self reloadSpringBoard];
	} else if ([shortcutItem.type isEqualToString:@"safemode"]) {
		NSLog(@"Entering Safe Mode through 3D Touch");
		[self enterSafeMode];
	} else if ([shortcutItem.type isEqualToString:@"repo1"] || [shortcutItem.type isEqualToString:@"repo2"]) {
		NSLog(@"Travelling to a repo through 3D Touch");
		[tabbar_ setSelectedIndex:1];
		SourcesController *sVC = (SourcesController*)[[tabbar_ viewControllers] objectAtIndex:1].childViewControllers[0];
		NSString *currentRepoURL = (NSString*)shortcutItem.userInfo[@"repoURL"];
		[sVC selectSourceWithURL:[NSString stringWithFormat:@"%@", currentRepoURL]];
	}
	
}

@end
