/* Cydia - iPhone UIKit Front-End for Debian APT
 * Copyright (C) 2008-2015  Jay Freeman (saurik)
*/

/* GNU General Public License, Version 3 {{{ */
/*
 * Cydia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Cydia is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cydia.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

// XXX: wtf/FastMalloc.h... wtf?
#define USE_SYSTEM_MALLOC 1

/* #include Directives {{{ */

#pragma mark - Limitless Headers

// Globals
#import "GeneralGlobals.h"
#import "UIGlobals.h"
#import "Flags.h"

// Display
#import "CYColor.hpp"
#import "DisplayHelpers.hpp"

// Debug
#import "Profiling.hpp"

// Network
#import "Networking.h"

// Utility
#import "CyteKit.h"
#import "GeneralHelpers.h"

// String
#import "NSString+Cydia.hpp"
#import "CYString.hpp"

// Collections
#import "CFArray+Sort.h"

// System
#import "SystemGlobals.h"
#import "SystemHelpers.h"

// Delegates
#import "Delegates.h"

#pragma mark - Headers

#include <unicode/ustring.h>
#include <unicode/utrans.h>

#include <objc/objc.h>
#include <objc/runtime.h>

#include <CoreGraphics/CoreGraphics.h>
#include <Foundation/Foundation.h>

#if 0
#define DEPLOYMENT_TARGET_MACOSX 1
#define CF_BUILDING_CF 1
#include <CoreFoundation/CFInternal.h>
#endif

#include <CoreFoundation/CFUniChar.h>

#include <SystemConfiguration/SystemConfiguration.h>

#include <UIKit/UIKit.h>
#include "iPhonePrivate.h"

#include <IOKit/IOKitLib.h>

#include <QuartzCore/CALayer.h>

#include <WebCore/WebCoreThread.h>
#include <WebKit/DOMHTMLIFrameElement.h>

#include <algorithm>
#include <iomanip>
#include <set>
#include <sstream>
#include <string>

#include <ext/stdio_filebuf.h>

#undef ABS

#import "Apt.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/reboot.h>

#include <dirent.h>
#include <fcntl.h>
#include <notify.h>
#include <dlfcn.h>

extern "C" {
#include <mach-o/nlist.h>
}

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <errno.h>

#include <Cytore.hpp>
#include "Sources.h"

#include "Substrate.hpp"
#import "Menes/Menes.h"

#include "Cydia/MIMEAddress.h"
#include "Cydia/LoadingViewController.h"
#include "Cydia/ProgressEvent.h"

#include "SDURLCache/SDURLCache.h"

#import "Defines.h"

#import "CancelStatus.hpp"
#import "CydiaStatus.hpp"
#import "Database.h"
#import "SourceStatus.hpp"

#import "CytoreHelpers.h"

#import "Source.h"
#import "CydiaOperation.h"
#import "CydiaClause.h"
#import "CydiaRelation.h"
#import "Package.h"
#import "Section.h"
#import "Logging.hpp"
#import "Database.h"
#import "Diversion.h"
#import "CydiaObject.h"
#import "CydiaWebViewController.h"
#import "NSURL+Cydia.h"
#import "AppCacheController.h"
#import "CydiaScript.h"
#import "ConfirmationController.h"
#import "CydiaProgressData.h"
#import "ProgressController.h"
#import "PackageCell.h"
#import "SectionCell.h"
#import "FileTable.h"
#import "CYPackageController.h"
#import "PackageListController.h"
#import "FilteredPackageListController.h"
#import "HomeController.h"
#import "UINavigationController+Cydia.h"
#import "CydiaTabBarController.h"
#import "CydiaURLProtocol.h"
#import "SectionController.h"
#import "SectionsController.h"
#import "ChangesController.h"
#import "SearchController.h"
#import "PackageSettingsController.h"
#import "InstalledController.h"
#import "SourceCell.h"
#import "SourcesController.h"

/* Stash Controller {{{ */
@interface StashController : CyteViewController {
    _H<UIActivityIndicatorView> spinner_;
    _H<UILabel> status_;
    _H<UILabel> caption_;
}

@end

@implementation StashController

- (void) loadView {
    UIView *view([[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]);
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self setView:view];

    [view setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];

    spinner_ = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    CGRect spinrect = [spinner_ frame];
    spinrect.origin.x = Retina([[self view] frame].size.width / 2 - spinrect.size.width / 2);
    spinrect.origin.y = [[self view] frame].size.height - 80.0f;
    [spinner_ setFrame:spinrect];
    [spinner_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    [view addSubview:spinner_];
    [spinner_ startAnimating];

    CGRect captrect;
    captrect.size.width = [[self view] frame].size.width;
    captrect.size.height = 40.0f;
    captrect.origin.x = 0;
    captrect.origin.y = Retina([[self view] frame].size.height / 2 - captrect.size.height * 2);
    caption_ = [[[UILabel alloc] initWithFrame:captrect] autorelease];
    [caption_ setText:UCLocalize("PREPARING_FILESYSTEM")];
    [caption_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [caption_ setFont:[UIFont boldSystemFontOfSize:28.0f]];
    [caption_ setTextColor:[UIColor whiteColor]];
    [caption_ setBackgroundColor:[UIColor clearColor]];
    [caption_ setShadowColor:[UIColor blackColor]];
    [caption_ setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:caption_];

    CGRect statusrect;
    statusrect.size.width = [[self view] frame].size.width;
    statusrect.size.height = 30.0f;
    statusrect.origin.x = 0;
    statusrect.origin.y = Retina([[self view] frame].size.height / 2 - statusrect.size.height);
    status_ = [[[UILabel alloc] initWithFrame:statusrect] autorelease];
    [status_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [status_ setText:UCLocalize("EXIT_WHEN_COMPLETE")];
    [status_ setFont:[UIFont systemFontOfSize:16.0f]];
    [status_ setTextColor:[UIColor whiteColor]];
    [status_ setBackgroundColor:[UIColor clearColor]];
    [status_ setShadowColor:[UIColor blackColor]];
    [status_ setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:status_];
}

- (void) releaseSubviews {
    spinner_ = nil;
    status_ = nil;
    caption_ = nil;

    [super releaseSubviews];
}

@end
/* }}} */

@interface CYURLCache : SDURLCache {
}

@end

@implementation CYURLCache

- (void) logEvent:(NSString *)event forRequest:(NSURLRequest *)request {
#if !ForRelease
    if (false);
    else if ([event isEqualToString:@"no-cache"])
        event = @"!!!";
    else if ([event isEqualToString:@"store"])
        event = @">>>";
    else if ([event isEqualToString:@"invalid"])
        event = @"???";
    else if ([event isEqualToString:@"memory"])
        event = @"mem";
    else if ([event isEqualToString:@"disk"])
        event = @"ssd";
    else if ([event isEqualToString:@"miss"])
        event = @"---";

    NSLog(@"%@: %@", event, [[request URL] absoluteString]);
#endif
}

- (void) storeCachedResponse:(NSCachedURLResponse *)cached forRequest:(NSURLRequest *)request {
    if (NSURLResponse *response = [cached response])
        if (NSString *mime = [response MIMEType])
            if ([mime isEqualToString:@"text/cache-manifest"]) {
                NSURL *url([response URL]);

#if !ForRelease
                NSLog(@"###: %@", [url absoluteString]);
#endif

                @synchronized (HostConfig_) {
                    [CachedURLs_ addObject:url];
                }
            }

    [super storeCachedResponse:cached forRequest:request];
}

- (void) createDiskCachePath {
    [super createDiskCachePath];
}

@end

@interface Cydia : UIApplication <
    ConfirmationControllerDelegate,
    DatabaseDelegate,
    CydiaDelegate
> {
    _H<UIWindow> window_;
    _H<CydiaTabBarController> tabbar_;
    _H<CyteTabBarController> emulated_;
    _H<AppCacheController> appcache_;

    _H<NSMutableArray> essential_;
    _H<NSMutableArray> broken_;

    Database *database_;

    _H<NSURL> starturl_;

    unsigned locked_;
    unsigned activity_;

    _H<StashController> stash_;

    bool loaded_;
}

@end

@implementation Cydia

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

- (void) returnToCydia {
    [self _loaded];
}

- (void) reloadSpringBoard {
    if (kCFCoreFoundationVersionNumber >= 700) // XXX: iOS 6.x
        system("/bin/launchctl stop com.apple.backboardd");
    else
        system("/bin/launchctl stop com.apple.SpringBoard");
    sleep(15);
    system("/usr/bin/killall backboardd SpringBoard");
}

- (void) _saveConfig {
    SaveConfig(database_);
}

// Navigation controller for the queuing badge.
- (UINavigationController *) queueNavigationController {
    NSArray *controllers = [tabbar_ viewControllers];
    return [controllers objectAtIndex:3];
}

- (void) unloadData {
    [tabbar_ unloadData];
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

- (void) _refreshIfPossible {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSDate *update([[NSDictionary dictionaryWithContentsOfFile:@ CacheState_] objectForKey:@"LastUpdate"]);

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

- (void) refreshIfPossible {
    [NSThread detachNewThreadSelector:@selector(_refreshIfPossible) toTarget:self withObject:nil];
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

- (void) updateData {
    [self _updateData];
}

- (void) updateDataAndLoad {
    [self _updateData];
    if ([database_ progressDelegate] == nil)
        [self _loaded];
}

- (void) update_ {
    [database_ update];
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
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

- (void) presentModalViewController:(UIViewController *)controller force:(BOOL)force {
    UINavigationController *navigation([[[UINavigationController alloc] initWithRootViewController:controller] autorelease]);

    UIViewController *parent;
    if (emulated_ == nil)
        parent = tabbar_;
    else if (!force)
        parent = emulated_;
    else {
        [self disemulate];
        parent = tabbar_;
    }

    if (IsWildcat_)
        [navigation setModalPresentationStyle:UIModalPresentationFormSheet];
    [parent presentModalViewController:navigation animated:YES];
}

- (ProgressController *) invokeNewProgress:(NSInvocation *)invocation forController:(UINavigationController *)navigation withTitle:(NSString *)title {
    ProgressController *progress([[[ProgressController alloc] initWithDatabase:database_ delegate:self] autorelease]);

    if (navigation != nil)
        [navigation pushViewController:progress animated:YES];
    else
        [self presentModalViewController:progress force:YES];

    [progress invoke:invocation withTitle:title];
    return progress;
}

- (void) detachNewProgressSelector:(SEL)selector toTarget:(id)target forController:(UINavigationController *)navigation title:(NSString *)title {
    [self invokeNewProgress:[NSInvocation invocationWithSelector:selector forTarget:target] forController:navigation withTitle:title];
}

- (void) repairWithInvocation:(NSInvocation *)invocation {
    _trace();
    [self invokeNewProgress:invocation forController:nil withTitle:@"REPAIRING"];
    _trace();
}

- (void) repairWithSelector:(SEL)selector {
    [self performSelectorOnMainThread:@selector(repairWithInvocation:) withObject:[NSInvocation invocationWithSelector:selector forTarget:database_] waitUntilDone:YES];
}

- (void) reloadData {
    [self reloadDataWithInvocation:nil];
    if ([database_ progressDelegate] == nil)
        [self _loaded];
}

- (void) syncData {
    [self _saveConfig];
    [self detachNewProgressSelector:@selector(update_) toTarget:self forController:nil title:@"UPDATING_SOURCES"];
}

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

    if (IsWildcat_)
        [confirm_ setModalPresentationStyle:UIModalPresentationFormSheet];
    [tabbar_ presentModalViewController:confirm_ animated:YES];

    return true;
}

- (void) queue {
    @synchronized (self) {
        [self perform];
    }
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

- (void) distUpgrade {
    @synchronized (self) {
        if (![database_ upgrade])
            return;
        [self perform];
    }
}

- (void) _uicache {
    _trace();
    system("/usr/bin/uicache");
    _trace();
}

- (void) uicache {
    UIProgressHUD *hud([self addProgressHUD]);
    [hud setText:UCLocalize("LOADING")];
    [self yieldToSelector:@selector(_uicache)];
    [self removeProgressHUD:hud];
}

- (void) perform_ {
    [database_ perform];
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(uicache) withObject:nil waitUntilDone:YES];
}

- (void) confirmWithNavigationController:(UINavigationController *)navigation {
    Queuing_ = false;
    [self lockSuspend];
    [self detachNewProgressSelector:@selector(perform_) toTarget:self forController:navigation title:@"RUNNING"];
    [self unlockSuspend];
}

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
                    system([[NSString stringWithFormat:@"/usr/libexec/cydia/cydo /bin/rm -f"
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

- (void) system:(NSString *)command {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    _trace();
    system([command UTF8String]);
    _trace();

    [pool release];
}

- (void) applicationWillSuspend {
    [database_ clean];
    [super applicationWillSuspend];
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

- (CyteViewController *) pageForPackage:(NSString *)name withReferrer:(NSString *)referrer {
    return [[[CYPackageController alloc] initWithDatabase:database_ forPackage:name withReferrer:referrer] autorelease];
}

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

- (void) applicationWillResignActive:(UIApplication *)application {
    // Stop refreshing if you get a phone call or lock the device.
    if ([tabbar_ updating])
        [tabbar_ cancelUpdate];

    if ([[self superclass] instancesRespondToSelector:@selector(applicationWillResignActive:)])
        [super applicationWillResignActive:application];
}

- (void) saveState {
    [[NSDictionary dictionaryWithObjectsAndKeys:
        @"InterfaceState", [tabbar_ navigationURLCollection],
        @"LastClosed", [NSDate date],
        @"InterfaceIndex", [NSNumber numberWithInt:[tabbar_ selectedIndex]],
    nil] writeToFile:@ SavedState_ atomically:YES];

    [self _saveConfig];
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
    [self yieldToSelector:@selector(system:) withObject:@"/usr/libexec/cydia/cydo /usr/libexec/cydia/free.sh"];
    UpdateExternalStatus(0);

    [self removeStashController];
    [self reloadSpringBoard];
}

- (void) setupViewControllers {
    tabbar_ = [[[CydiaTabBarController alloc] initWithDatabase:database_] autorelease];

    NSMutableArray *items;
    if (kCFCoreFoundationVersionNumber < 800) {
        items = [NSMutableArray arrayWithObjects:
            [[[UITabBarItem alloc] initWithTitle:@"Cydia" image:[UIImage imageNamed:@"home.png"] tag:0] autorelease],
            [[[UITabBarItem alloc] initWithTitle:UCLocalize("SOURCES") image:[UIImage imageNamed:@"install.png"] tag:0] autorelease],
            [[[UITabBarItem alloc] initWithTitle:UCLocalize("CHANGES") image:[UIImage imageNamed:@"changes.png"] tag:0] autorelease],
            [[[UITabBarItem alloc] initWithTitle:UCLocalize("INSTALLED") image:[UIImage imageNamed:@"manage.png"] tag:0] autorelease],
            [[[UITabBarItem alloc] initWithTitle:UCLocalize("SEARCH") image:[UIImage imageNamed:@"search.png"] tag:0] autorelease],
        nil];
    } else {
        items = [NSMutableArray arrayWithObjects:
            [[[UITabBarItem alloc] initWithTitle:@"Cydia" image:[UIImage imageNamed:@"home7.png"] selectedImage:[UIImage imageNamed:@"home7s.png"]] autorelease],
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

- (void) applicationDidFinishLaunching:(id)unused {
    //[NSThread detachNewThreadSelector:@selector(_sendMemoryWarningNotifications) toTarget:self withObject:nil];

_trace();
    if ([self respondsToSelector:@selector(setApplicationSupportsShakeToEdit:)])
        [self setApplicationSupportsShakeToEdit:NO];

    @synchronized (HostConfig_) {
        [BridgedHosts_ addObject:[[NSURL URLWithString:CydiaURL(@"")] host]];
    }

    [NSURLCache setSharedURLCache:[[[CYURLCache alloc]
        initWithMemoryCapacity:524288
        diskCapacity:10485760
        diskPath:Cache("SDURLCache")
    ] autorelease]];

    [CydiaWebViewController _initialize];

    [NSURLProtocol registerClass:[CydiaURLProtocol class]];

    // this would disallow http{,s} URLs from accessing this data
    //[WebView registerURLSchemeAsLocal:@"cydia"];

    Font12_ = [UIFont systemFontOfSize:12];
    Font12Bold_ = [UIFont boldSystemFontOfSize:12];
    Font14_ = [UIFont systemFontOfSize:14];
    Font18_ = [UIFont systemFontOfSize:18];
    Font18Bold_ = [UIFont boldSystemFontOfSize:18];
    Font22Bold_ = [UIFont boldSystemFontOfSize:22];

    essential_ = [NSMutableArray arrayWithCapacity:4];
    broken_ = [NSMutableArray arrayWithCapacity:4];

    // XXX: I really need this thing... like, seriously... I'm sorry
    appcache_ = [[[AppCacheController alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/appcache/", UI_]]] autorelease];
    [appcache_ reloadData];

    window_ = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [window_ orderFront:self];
    [window_ makeKey:self];
    [window_ setHidden:NO];

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

    database_ = [Database sharedInstance];
    [database_ setDelegate:self];

    [window_ setUserInteractionEnabled:NO];
    [self setupViewControllers];

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

    [self performSelector:@selector(loadData) withObject:nil afterDelay:0];
_trace();
}

- (NSArray *) defaultStartPages {
    NSMutableArray *standard = [NSMutableArray array];
    [standard addObject:[NSArray arrayWithObject:@"cydia://home"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://sources"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://changes"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://installed"]];
    [standard addObject:[NSArray arrayWithObject:@"cydia://search"]];
    return standard;
}

- (void) loadData {
_trace();
    if ([emulated_ modalViewController] != nil)
        [emulated_ dismissModalViewControllerAnimated:YES];
    [window_ setUserInteractionEnabled:NO];

    [self reloadDataWithInvocation:nil];
    [self refreshIfPossible];
    [self disemulate];

    NSDictionary *state([NSDictionary dictionaryWithContentsOfFile:@ SavedState_]);

    int savedIndex = [[state objectForKey:@"InterfaceIndex"] intValue];
    NSArray *saved = [[[state objectForKey:@"InterfaceState"] mutableCopy] autorelease];
    int standardIndex = 0;
    NSArray *standard = [self defaultStartPages];

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

    // (Try to) show the startup URL.
    if (starturl_ != nil) {
        [self openCydiaURL:starturl_ forExternal:YES];
        starturl_ = nil;
    }
}

- (void) showActionSheet:(UIActionSheet *)sheet fromItem:(UIBarButtonItem *)item {
    if (!IsWildcat_) {
       [sheet addButtonWithTitle:UCLocalize("CANCEL")];
       [sheet setCancelButtonIndex:[sheet numberOfButtons] - 1];
    }

    if (item != nil && IsWildcat_) {
        [sheet showFromBarButtonItem:item animated:YES];
    } else {
        [sheet showInView:window_];
    }
}

- (void) addProgressEvent:(CydiaProgressEvent *)event forTask:(NSString *)task {
    id<ProgressDelegate> progress([database_ progressDelegate] ?: [self invokeNewProgress:nil forController:nil withTitle:task]);
    [progress setTitle:task];
    [progress addProgressEvent:event];
}

- (void) addProgressEventForTask:(NSArray *)data {
    CydiaProgressEvent *event([data objectAtIndex:0]);
    NSString *task([data count] < 2 ? nil : [data objectAtIndex:1]);
    [self addProgressEvent:event forTask:task];
}

- (void) addProgressEventOnMainThread:(CydiaProgressEvent *)event forTask:(NSString *)task {
    [self performSelectorOnMainThread:@selector(addProgressEventForTask:) withObject:[NSArray arrayWithObjects:event, task, nil] waitUntilDone:YES];
}

@end

/*IMP alloc_;
id Alloc_(id self, SEL selector) {
    id object = alloc_(self, selector);
    lprintf("[%s]A-%p\n", self->isa->name, object);
    return object;
}*/

/*IMP dealloc_;
id Dealloc_(id self, SEL selector) {
    id object = dealloc_(self, selector);
    lprintf("[%s]D-%p\n", self->isa->name, object);
    return object;
}*/

Class $NSURLConnection;

MSHook(id, NSURLConnection$init$, NSURLConnection *self, SEL _cmd, NSURLRequest *request, id delegate, BOOL usesCache, int64_t maxContentLength, BOOL startImmediately, NSDictionary *connectionProperties) {
    NSMutableURLRequest *copy([[request mutableCopy] autorelease]);

    NSURL *url([copy URL]);

    NSString *host([url host]);
    NSString *scheme([[url scheme] lowercaseString]);

    NSString *compound([NSString stringWithFormat:@"%@:%@", scheme, host]);

    @synchronized (HostConfig_) {
        if ([copy respondsToSelector:@selector(setHTTPShouldUsePipelining:)])
            if ([PipelinedHosts_ containsObject:host] || [PipelinedHosts_ containsObject:compound])
                [copy setHTTPShouldUsePipelining:YES];

        if (NSString *control = [copy valueForHTTPHeaderField:@"Cache-Control"])
            if ([control isEqualToString:@"max-age=0"])
                if ([CachedURLs_ containsObject:url]) {
#if !ForRelease
                    NSLog(@"~~~: %@", url);
#endif

                    [copy setCachePolicy:NSURLRequestReturnCacheDataDontLoad];

                    [copy setValue:nil forHTTPHeaderField:@"Cache-Control"];
                    [copy setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
                    [copy setValue:nil forHTTPHeaderField:@"If-None-Match"];
                }
    }

    if ((self = _NSURLConnection$init$(self, _cmd, copy, delegate, usesCache, maxContentLength, startImmediately, connectionProperties)) != nil) {
    } return self;
}

Class $WAKWindow;

static CGSize $WAKWindow$screenSize(WAKWindow *self, SEL _cmd) {
    CGSize size([[UIScreen mainScreen] bounds].size);
    /*if ([$WAKWindow respondsToSelector:@selector(hasLandscapeOrientation)])
        if ([$WAKWindow hasLandscapeOrientation])
            std::swap(size.width, size.height);*/
    return size;
}

Class $NSUserDefaults;

MSHook(id, NSUserDefaults$objectForKey$, NSUserDefaults *self, SEL _cmd, NSString *key) {
    if ([key respondsToSelector:@selector(isEqualToString:)] && [key isEqualToString:@"WebKitLocalStorageDatabasePathPreferenceKey"])
        return Cache("LocalStorage");
    return _NSUserDefaults$objectForKey$(self, _cmd, key);
}

static NSMutableDictionary *AutoreleaseDeepMutableCopyOfDictionary(CFTypeRef type) {
    if (type == NULL)
        return nil;
    if (CFGetTypeID(type) != CFDictionaryGetTypeID())
        return nil;
    CFTypeRef copy(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, type, kCFPropertyListMutableContainers));
    CFRelease(type);
    return [(NSMutableDictionary *) copy autorelease];
}

int mainOld(int argc, char *argv[]) {
    int fd(open("/tmp/cydia.log", O_WRONLY | O_APPEND | O_CREAT, 0644));
    dup2(fd, 2);
    close(fd);

    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    _trace();

    UpdateExternalStatus(0);

    UIScreen *screen([UIScreen mainScreen]);
    if ([screen respondsToSelector:@selector(scale)])
        ScreenScale_ = [screen scale];
    else
        ScreenScale_ = 1;

    UIDevice *device([UIDevice currentDevice]);
    if ([device respondsToSelector:@selector(userInterfaceIdiom)]) {
        UIUserInterfaceIdiom idiom([device userInterfaceIdiom]);
        if (idiom == UIUserInterfaceIdiomPad)
            IsWildcat_ = true;
    }

    Idiom_ = IsWildcat_ ? @"ipad" : @"iphone";

    RegEx pattern("([0-9]+\\.[0-9]+).*");

    if (pattern([device systemVersion]))
        Firmware_ = pattern[1];
    if (pattern(Cydia_))
        Major_ = pattern[1];

    SessionData_ = [NSMutableDictionary dictionaryWithCapacity:4];

    HostConfig_ = [[[NSObject alloc] init] autorelease];
    @synchronized (HostConfig_) {
        BridgedHosts_ = [NSMutableSet setWithCapacity:4];
        InsecureHosts_ = [NSMutableSet setWithCapacity:4];
        PipelinedHosts_ = [NSMutableSet setWithCapacity:4];
        CachedURLs_ = [NSMutableSet setWithCapacity:32];
    }

    NSString *ui(@"ui/ios");
    if (Idiom_ != nil)
        ui = [ui stringByAppendingString:[NSString stringWithFormat:@"~%@", Idiom_]];
    ui = [ui stringByAppendingString:[NSString stringWithFormat:@"/%@", Major_]];
    UI_ = CydiaURL(ui);

    PackageName = reinterpret_cast<CYString &(*)(Package *, SEL)>(method_getImplementation(class_getInstanceMethod([Package class], @selector(cyname))));

    /* Library Hacks {{{ */
    class_addMethod(objc_getClass("DOMNodeList"), @selector(countByEnumeratingWithState:objects:count:), (IMP) &DOMNodeList$countByEnumeratingWithState$objects$count$, "I20@0:4^{NSFastEnumerationState}8^@12I16");

    $WAKWindow = objc_getClass("WAKWindow");
    if ($WAKWindow != NULL)
        if (Method method = class_getInstanceMethod($WAKWindow, @selector(screenSize)))
            method_setImplementation(method, (IMP) &$WAKWindow$screenSize);

    $NSURLConnection = objc_getClass("NSURLConnection");
    Method NSURLConnection$init$(class_getInstanceMethod($NSURLConnection, @selector(_initWithRequest:delegate:usesCache:maxContentLength:startImmediately:connectionProperties:)));
    if (NSURLConnection$init$ != NULL) {
        _NSURLConnection$init$ = reinterpret_cast<id (*)(NSURLConnection *, SEL, NSURLRequest *, id, BOOL, int64_t, BOOL, NSDictionary *)>(method_getImplementation(NSURLConnection$init$));
        method_setImplementation(NSURLConnection$init$, reinterpret_cast<IMP>(&$NSURLConnection$init$));
    }

    $NSUserDefaults = objc_getClass("NSUserDefaults");
    Method NSUserDefaults$objectForKey$(class_getInstanceMethod($NSUserDefaults, @selector(objectForKey:)));
    if (NSUserDefaults$objectForKey$ != NULL) {
        _NSUserDefaults$objectForKey$ = reinterpret_cast<id (*)(NSUserDefaults *, SEL, NSString *)>(method_getImplementation(NSUserDefaults$objectForKey$));
        method_setImplementation(NSUserDefaults$objectForKey$, reinterpret_cast<IMP>(&$NSUserDefaults$objectForKey$));
    }
    /* }}} */
    /* Set Locale {{{ */
    Locale_ = CFLocaleCopyCurrent();
    Languages_ = [NSLocale preferredLanguages];

    //CFStringRef locale(CFLocaleGetIdentifier(Locale_));
    //NSLog(@"%@", [Languages_ description]);

    const char *lang;
    if (Locale_ != NULL)
        lang = [(NSString *) CFLocaleGetIdentifier(Locale_) UTF8String];
    else if (Languages_ != nil && [Languages_ count] != 0)
        lang = [[Languages_ objectAtIndex:0] UTF8String];
    else
        // XXX: consider just setting to C and then falling through?
        lang = NULL;

    if (lang != NULL) {
        RegEx pattern("([a-z][a-z])(?:-[A-Za-z]*)?(_[A-Z][A-Z])?");
        lang = !pattern(lang) ? NULL : [pattern->*@"%1$@%2$@" UTF8String];
    }

    NSLog(@"Setting Language: %s", lang);

    if (lang != NULL) {
        setenv("LANG", lang, true);
        std::setlocale(LC_ALL, lang);
    }
    /* }}} */
    /* Index Collation {{{ */
    if (Class $UILocalizedIndexedCollation = objc_getClass("UILocalizedIndexedCollation")) { @try {
        NSBundle *bundle([NSBundle bundleForClass:$UILocalizedIndexedCollation]);
        NSString *path([bundle pathForResource:@"UITableViewLocalizedSectionIndex" ofType:@"plist"]);
        //path = @"/System/Library/Frameworks/UIKit.framework/.lproj/UITableViewLocalizedSectionIndex.plist";
        NSDictionary *dictionary([NSDictionary dictionaryWithContentsOfFile:path]);
        _H<UILocalizedIndexedCollation> collation([[[$UILocalizedIndexedCollation alloc] initWithDictionary:dictionary] autorelease]);

        CollationLocale_ = MSHookIvar<NSLocale *>(collation, "_locale");

        if (kCFCoreFoundationVersionNumber >= 800 && [[CollationLocale_ localeIdentifier] isEqualToString:@"zh@collation=stroke"]) {
            CollationThumbs_ = [NSArray arrayWithObjects:@"1",@"•",@"4",@"•",@"7",@"•",@"10",@"•",@"13",@"•",@"16",@"•",@"19",@"A",@"•",@"E",@"•",@"I",@"•",@"M",@"•",@"R",@"•",@"V",@"•",@"Z",@"#",nil];
            for (NSInteger offset : (NSInteger[]) {0,1,3,4,6,7,9,10,12,13,15,16,18,25,26,29,30,33,34,37,38,42,43,46,47,50,51})
                CollationOffset_.push_back(offset);
            CollationTitles_ = [NSArray arrayWithObjects:@"1 畫",@"2 畫",@"3 畫",@"4 畫",@"5 畫",@"6 畫",@"7 畫",@"8 畫",@"9 畫",@"10 畫",@"11 畫",@"12 畫",@"13 畫",@"14 畫",@"15 畫",@"16 畫",@"17 畫",@"18 畫",@"19 畫",@"20 畫",@"21 畫",@"22 畫",@"23 畫",@"24 畫",@"25 畫以上",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
            CollationStarts_ = [NSArray arrayWithObjects:@"一",@"丁",@"丈",@"不",@"且",@"丞",@"串",@"並",@"亭",@"乘",@"乾",@"傀",@"亂",@"僎",@"僵",@"儐",@"償",@"叢",@"儳",@"嚴",@"儷",@"儻",@"囌",@"囑",@"廳",@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
        } else {

        CollationThumbs_ = [collation sectionIndexTitles];
        for (size_t index(0), end([CollationThumbs_ count]); index != end; ++index)
            CollationOffset_.push_back([collation sectionForSectionIndexTitleAtIndex:index]);

        CollationTitles_ = [collation sectionTitles];
        CollationStarts_ = MSHookIvar<NSArray *>(collation, "_sectionStartStrings");

        NSString *transform = MSHookIvar<NSString *>(collation, "_transform");
        if (transform != nil) {
            /*if ([collation respondsToSelector:@selector(transformedCollationStringForString:)])
                CollationModify_ = [=](NSString *value) { return [collation transformedCollationStringForString:value]; };*/
            const UChar *uid(reinterpret_cast<const UChar *>([transform cStringUsingEncoding:NSUnicodeStringEncoding]));
            UErrorCode code(U_ZERO_ERROR);
            CollationTransl_ = utrans_openU(uid, -1, UTRANS_FORWARD, NULL, 0, NULL, &code);
            if (!U_SUCCESS(code))
                NSLog(@"%s", u_errorName(code));
        }

        }
    } @catch (NSException *e) {
        NSLog(@"%@", e);
        goto hard;
    } } else hard: {
        CollationLocale_ = [[[NSLocale alloc] initWithLocaleIdentifier:@"en@collation=dictionary"] autorelease];

        CollationThumbs_ = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        for (NSInteger offset(0); offset != 28; ++offset)
            CollationOffset_.push_back(offset);

        CollationTitles_ = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        CollationStarts_ = [NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
    }
    /* }}} */
    /* Parse Arguments {{{ */
    bool substrate(false);

    if (argc != 0) {
        char **args(argv);
        int arge(1);

        for (int argi(1); argi != argc; ++argi)
            if (strcmp(argv[argi], "--") == 0) {
                arge = argi;
                argv[argi] = argv[0];
                argv += argi;
                argc -= argi;
                break;
            }

        for (int argi(1); argi != arge; ++argi)
            if (strcmp(args[argi], "--substrate") == 0)
                substrate = true;
            else
                fprintf(stderr, "unknown argument: %s\n", args[argi]);
    }
    /* }}} */

    App_ = [[NSBundle mainBundle] bundlePath];
    Advanced_ = YES;

    Cache_ = [[NSString stringWithFormat:@"%@/Library/Caches/com.saurik.Cydia", @"/var/mobile"] retain];
    mkdir([Cache_ UTF8String], 0755);

    /*Method alloc = class_getClassMethod([NSObject class], @selector(alloc));
    alloc_ = alloc->method_imp;
    alloc->method_imp = (IMP) &Alloc_;*/

    /*Method dealloc = class_getClassMethod([NSObject class], @selector(dealloc));
    dealloc_ = dealloc->method_imp;
    dealloc->method_imp = (IMP) &Dealloc_;*/

    void *gestalt(dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY));
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));

    /* System Information {{{ */
    size_t size;

    int maxproc;
    size = sizeof(maxproc);
    if (sysctlbyname("kern.maxproc", &maxproc, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.maxproc\", ?)");
    else if (maxproc < 64) {
        maxproc = 64;
        if (sysctlbyname("kern.maxproc", NULL, NULL, &maxproc, sizeof(maxproc)) == -1)
            perror("sysctlbyname(\"kern.maxproc\", #)");
    }

    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *osversion = new char[size];
    if (sysctlbyname("kern.osversion", osversion, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.osversion\", ?)");
    else
        System_ = [NSString stringWithUTF8String:osversion];

    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = new char[size];
    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"hw.machine\", ?)");
    else
        Machine_ = machine;

    int64_t usermem(0);
    size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1)
        usermem = 0;

    SerialNumber_ = (NSString *) CYIOGetValue("IOService:/", @"IOPlatformSerialNumber");
    ChipID_ = [CYHex((NSData *) CYIOGetValue("IODeviceTree:/chosen", @"unique-chip-id"), true) uppercaseString];
    BBSNum_ = CYHex((NSData *) CYIOGetValue("IOService:/AppleARMPE/baseband", @"snum"), false);

    UniqueID_ = UniqueIdentifier(device);

    if (NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:@"/Applications/MobileSafari.app/Info.plist"]) {
        Product_ = [info objectForKey:@"SafariProductVersion"];
        Safari_ = [info objectForKey:@"CFBundleVersion"];
    }

    NSString *agent([NSString stringWithFormat:@"Cydia/%@ CyF/%.2f", Cydia_, kCFCoreFoundationVersionNumber]);

    if (RegEx match = RegEx("([0-9]+(\\.[0-9]+)+).*", Safari_))
        agent = [NSString stringWithFormat:@"Safari/%@ %@", match[1], agent];
    if (RegEx match = RegEx("([0-9]+[A-Z][0-9]+[a-z]?).*", System_))
        agent = [NSString stringWithFormat:@"Mobile/%@ %@", match[1], agent];
    if (RegEx match = RegEx("([0-9]+(\\.[0-9]+)+).*", Product_))
        agent = [NSString stringWithFormat:@"Version/%@ %@", match[1], agent];

    UserAgent_ = agent;
    /* }}} */
    /* Load Database {{{ */
    SectionMap_ = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sections" ofType:@"plist"]] autorelease];

    _trace();
    mkdir("/var/mobile/Library/Cydia", 0755);
    MetaFile_.Open("/var/mobile/Library/Cydia/metadata.cb0");
    _trace();

    Values_ = AutoreleaseDeepMutableCopyOfDictionary(CFPreferencesCopyAppValue(CFSTR("CydiaValues"), CFSTR("com.saurik.Cydia")));
    Sections_ = AutoreleaseDeepMutableCopyOfDictionary(CFPreferencesCopyAppValue(CFSTR("CydiaSections"), CFSTR("com.saurik.Cydia")));
    Sources_ = AutoreleaseDeepMutableCopyOfDictionary(CFPreferencesCopyAppValue(CFSTR("CydiaSources"), CFSTR("com.saurik.Cydia")));
    Version_ = [(NSNumber *) CFPreferencesCopyAppValue(CFSTR("CydiaVersion"), CFSTR("com.saurik.Cydia")) autorelease];

    _trace();
    NSDictionary *metadata([[[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/lib/cydia/metadata.plist"] autorelease]);

    if (Values_ == nil)
        Values_ = [metadata objectForKey:@"Values"];
    if (Values_ == nil)
        Values_ = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];

    if (Sections_ == nil)
        Sections_ = [metadata objectForKey:@"Sections"];
    if (Sections_ == nil)
        Sections_ = [[[NSMutableDictionary alloc] initWithCapacity:32] autorelease];

    if (Sources_ == nil)
        Sources_ = [metadata objectForKey:@"Sources"];
    if (Sources_ == nil)
        Sources_ = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];

    // XXX: this wrong, but in a way that doesn't matter :/
    if (Version_ == nil)
        Version_ = [metadata objectForKey:@"Version"];
    if (Version_ == nil)
        Version_ = [NSNumber numberWithUnsignedInt:0];

    if (NSDictionary *packages = [metadata objectForKey:@"Packages"]) {
        bool fail(false);
        CFDictionaryApplyFunction((CFDictionaryRef) packages, &PackageImport, &fail);
        _trace();
        if (fail)
            NSLog(@"unable to import package preferences... from 2010? oh well :/");
    }

    if ([Version_ unsignedIntValue] == 0) {
        CydiaAddSource(@"http://apt.thebigboss.org/repofiles/cydia/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://apt.modmyi.com/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://cydia.zodttd.com/repo/cydia/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://repo666.ultrasn0w.com/", @"./");

        Version_ = [NSNumber numberWithUnsignedInt:1];

        if (NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:@ CacheState_]) {
            [cache removeObjectForKey:@"LastUpdate"];
            [cache writeToFile:@ CacheState_ atomically:YES];
        }
    }

    _H<NSMutableArray> broken([NSMutableArray array]);
    for (NSString *key in (id) Sources_)
        if ([key rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"# "]].location != NSNotFound || ![([[Sources_ objectForKey:key] objectForKey:@"URI"] ?: @"/") hasSuffix:@"/"])
            [broken addObject:key];
    if ([broken count] != 0)
        for (NSString *key in (id) broken)
            [Sources_ removeObjectForKey:key];
    broken = nil;

    SaveConfig(nil);
    system("/usr/libexec/cydia/cydo /bin/rm -f /var/lib/cydia/metadata.plist");
    /* }}} */

    Finishes_ = [NSArray arrayWithObjects:@"return", @"reopen", @"restart", @"reload", @"reboot", nil];

    if (kCFCoreFoundationVersionNumber > 1000)
        system("/usr/libexec/cydia/cydo /usr/libexec/cydia/setnsfpn /var/lib");
    
    int version = [NSString stringWithContentsOfFile:@"/var/lib/cydia/firmware.ver" encoding:NSUTF8StringEncoding error:nil].intValue;

    if (access("/User", F_OK) != 0 || version != 6) {
        _trace();
        system("/usr/libexec/cydia/cydo /usr/libexec/cydia/firmware.sh");
        _trace();
    }

    if (access("/tmp/cydia.chk", F_OK) == 0) {
        if (unlink([Cache("pkgcache.bin") UTF8String]) == -1)
            _assert(errno == ENOENT);
        if (unlink([Cache("srcpkgcache.bin") UTF8String]) == -1)
            _assert(errno == ENOENT);
    }

    system("/usr/libexec/cydia/cydo /bin/ln -sf /var/mobile/Library/Caches/com.saurik.Cydia/sources.list /etc/apt/sources.list.d/cydia.list");

    /* APT Initialization {{{ */
    _assert(pkgInitConfig(*_config));
    _assert(pkgInitSystem(*_config, _system));

    if (lang != NULL)
        _config->Set("APT::Acquire::Translation", lang);

    // XXX: this timeout might be important :(
    //_config->Set("Acquire::http::Timeout", 15);

    _config->Set("Acquire::http::MaxParallel", usermem >= 384 * 1024 * 1024 ? 16 : 3);

    mkdir([Cache("archives") UTF8String], 0755);
    mkdir([Cache("archives/partial") UTF8String], 0755);
    _config->Set("Dir::Cache", [Cache_ UTF8String]);

    symlink("/var/lib/apt/extended_states", [Cache("extended_states") UTF8String]);
    _config->Set("Dir::State", [Cache_ UTF8String]);

    mkdir([Cache("lists") UTF8String], 0755);
    mkdir([Cache("lists/partial") UTF8String], 0755);
    mkdir([Cache("periodic") UTF8String], 0755);
    _config->Set("Dir::State::Lists", [Cache("lists") UTF8String]);

    std::string logs("/var/mobile/Library/Logs/Cydia");
    mkdir(logs.c_str(), 0755);
    _config->Set("Dir::Log::Terminal", logs + "/apt.log");

    _config->Set("Dir::Bin::dpkg", "/usr/libexec/cydia/cydo");
    /* }}} */
    /* Color Choices {{{ */
    space_ = CGColorSpaceCreateDeviceRGB();

    Blue_.Set(space_, 0.2, 0.2, 1.0, 1.0);
    Blueish_.Set(space_, 0x19/255.f, 0x32/255.f, 0x50/255.f, 1.0);
    Black_.Set(space_, 0.0, 0.0, 0.0, 1.0);
    Folder_.Set(space_, 0x8e/255.f, 0x8e/255.f, 0x93/255.f, 1.0);
    Off_.Set(space_, 0.9, 0.9, 0.9, 1.0);
    White_.Set(space_, 1.0, 1.0, 1.0, 1.0);
    Gray_.Set(space_, 0.4, 0.4, 0.4, 1.0);
    Green_.Set(space_, 0.0, 0.5, 0.0, 1.0);
    Purple_.Set(space_, 0.0, 0.0, 0.7, 1.0);
    Purplish_.Set(space_, 0.4, 0.4, 0.8, 1.0);

    InstallingColor_ = [UIColor colorWithRed:0.88f green:1.00f blue:0.88f alpha:1.00f];
    RemovingColor_ = [UIColor colorWithRed:1.00f green:0.88f blue:0.88f alpha:1.00f];
    /* }}}*/
    /* UIKit Configuration {{{ */
    // XXX: I have a feeling this was important
    //UIKeyboardDisableAutomaticAppearance();
    /* }}} */

    $SBSSetInterceptsMenuButtonForever = reinterpret_cast<void (*)(bool)>(dlsym(RTLD_DEFAULT, "SBSSetInterceptsMenuButtonForever"));
    $SBSCopyIconImagePNGDataForDisplayIdentifier = reinterpret_cast<NSData *(*)(NSString *)>(dlsym(RTLD_DEFAULT, "SBSCopyIconImagePNGDataForDisplayIdentifier"));

    const char *symbol(kCFCoreFoundationVersionNumber >= 800 ? "MGGetBoolAnswer" : "GSSystemHasCapability");
    BOOL (*GSSystemHasCapability)(CFStringRef) = reinterpret_cast<BOOL (*)(CFStringRef)>(dlsym(RTLD_DEFAULT, symbol));
    bool fast = GSSystemHasCapability != NULL && GSSystemHasCapability(CFSTR("armv7"));

    PulseInterval_ = fast ? 50000 : 500000;

    Colon_ = UCLocalize("COLON_DELIMITED");
    Elision_ = UCLocalize("ELISION");
    Error_ = UCLocalize("ERROR");
    Warning_ = UCLocalize("WARNING");

    _trace();
    int value(UIApplicationMain(argc, argv, @"Cydia", @"Cydia"));

    CGColorSpaceRelease(space_);
    CFRelease(Locale_);

    [pool release];
    return value;
}
