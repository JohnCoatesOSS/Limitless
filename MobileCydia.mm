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

// CydiaScript {{{
@interface NSObject (CydiaScript)
- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context;
@end

@implementation NSObject (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    return self;
}

@end

@implementation NSArray (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    WebScriptObject *object([context evaluateWebScript:@"[]"]);
    for (size_t i(0), e([self count]); i != e; ++i)
        [object setWebScriptValueAtIndex:i value:[[self objectAtIndex:i] Cydia$webScriptObjectInContext:context]];
    return object;
}

@end

@implementation NSDictionary (CydiaScript)

- (id) Cydia$webScriptObjectInContext:(WebScriptObject *)context {
    WebScriptObject *object([context evaluateWebScript:@"({})"]);
    for (id i in self)
        [object setValue:[[self objectForKey:i] Cydia$webScriptObjectInContext:context] forKey:i];
    return object;
}

@end
// }}}

/* Confirmation Controller {{{ */
bool DepSubstrate(const pkgCache::VerIterator &iterator) {
    if (!iterator.end())
        for (pkgCache::DepIterator dep(iterator.DependsList()); !dep.end(); ++dep) {
            if (dep->Type != pkgCache::Dep::Depends && dep->Type != pkgCache::Dep::PreDepends)
                continue;
            pkgCache::PkgIterator package(dep.TargetPkg());
            if (package.end())
                continue;
            if (strcmp(package.Name(), "mobilesubstrate") == 0)
                return true;
        }

    return false;
}

@protocol ConfirmationControllerDelegate
- (void) cancelAndClear:(bool)clear;
- (void) confirmWithNavigationController:(UINavigationController *)navigation;
- (void) queue;
@end

@interface ConfirmationController : CydiaWebViewController {
    _transient Database *database_;

    _H<UIAlertView> essential_;

    _H<NSDictionary> changes_;
    _H<NSMutableArray> issues_;
    _H<NSDictionary> sizes_;

    BOOL substrate_;
}

- (id) initWithDatabase:(Database *)database;

@end

@implementation ConfirmationController

- (void) complete {
    if (substrate_)
        RestartSubstrate_ = true;
    [delegate_ confirmWithNavigationController:[self navigationController]];
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button {
    NSString *context([alert context]);

    if ([context isEqualToString:@"remove"]) {
        if (button == [alert cancelButtonIndex])
            [self _doContinue];
        else if (button == [alert firstOtherButtonIndex]) {
            [self performSelector:@selector(complete) withObject:nil afterDelay:0];
        }

        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else if ([context isEqualToString:@"unable"]) {
        [self dismissModalViewControllerAnimated:YES];
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else {
        [super alertView:alert clickedButtonAtIndex:button];
    }
}

- (void) _doContinue {
    [delegate_ cancelAndClear:NO];
    [self dismissModalViewControllerAnimated:YES];
}

- (id) invokeDefaultMethodWithArguments:(NSArray *)args {
    [self performSelectorOnMainThread:@selector(_doContinue) withObject:nil waitUntilDone:NO];
    return nil;
}

- (void) webView:(WebView *)view didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:view didClearWindowObject:window forFrame:frame];

    [window setValue:[[NSDictionary dictionaryWithObjectsAndKeys:
        (id) changes_, @"changes",
        (id) issues_, @"issues",
        (id) sizes_, @"sizes",
        self, @"queue",
    nil] Cydia$webScriptObjectInContext:window] forKey:@"cydiaConfirm"];
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;

        NSMutableArray *installs([NSMutableArray arrayWithCapacity:16]);
        NSMutableArray *reinstalls([NSMutableArray arrayWithCapacity:16]);
        NSMutableArray *upgrades([NSMutableArray arrayWithCapacity:16]);
        NSMutableArray *downgrades([NSMutableArray arrayWithCapacity:16]);
        NSMutableArray *removes([NSMutableArray arrayWithCapacity:16]);

        bool remove(false);

        pkgCacheFile &cache([database_ cache]);
        NSArray *packages([database_ packages]);
        pkgDepCache::Policy *policy([database_ policy]);

        issues_ = [NSMutableArray arrayWithCapacity:4];

        for (Package *package in packages) {
            pkgCache::PkgIterator iterator([package iterator]);
            NSString *name([package id]);

            if ([package broken]) {
                NSMutableArray *reasons([NSMutableArray arrayWithCapacity:4]);

                [issues_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    name, @"package",
                    reasons, @"reasons",
                nil]];

                pkgCache::VerIterator ver(cache[iterator].InstVerIter(cache));
                if (ver.end())
                    continue;

                for (pkgCache::DepIterator dep(ver.DependsList()); !dep.end(); ) {
                    pkgCache::DepIterator start;
                    pkgCache::DepIterator end;
                    dep.GlobOr(start, end); // ++dep

                    if (!cache->IsImportantDep(end))
                        continue;
                    if ((cache[end] & pkgDepCache::DepGInstall) != 0)
                        continue;

                    NSMutableArray *clauses([NSMutableArray arrayWithCapacity:4]);

                    [reasons addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithUTF8String:start.DepType()], @"relationship",
                        clauses, @"clauses",
                    nil]];

                    _forever {
                        NSString *reason, *installed((NSString *) [WebUndefined undefined]);

                        pkgCache::PkgIterator target(start.TargetPkg());
                        if (target->ProvidesList != 0)
                            reason = @"missing";
                        else {
                            pkgCache::VerIterator ver(cache[target].InstVerIter(cache));
                            if (!ver.end()) {
                                reason = @"installed";
                                installed = [NSString stringWithUTF8String:ver.VerStr()];
                            } else if (!cache[target].CandidateVerIter(cache).end())
                                reason = @"uninstalled";
                            else if (target->ProvidesList == 0)
                                reason = @"uninstallable";
                            else
                                reason = @"virtual";
                        }

                        NSDictionary *version(start.TargetVer() == 0 ? (NSDictionary *) [NSNull null] : [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithUTF8String:start.CompType()], @"operator",
                            [NSString stringWithUTF8String:start.TargetVer()], @"value",
                        nil]);

                        [clauses addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithUTF8String:start.TargetPkg().Name()], @"package",
                            version, @"version",
                            reason, @"reason",
                            installed, @"installed",
                        nil]];

                        // yes, seriously. (wtf?)
                        if (start == end)
                            break;
                        ++start;
                    }
                }
            }

            pkgDepCache::StateCache &state(cache[iterator]);

            static RegEx special_r("(firmware|gsc\\..*|cy\\+.*)");

            if (state.NewInstall())
                [installs addObject:name];
            // XXX: else if (state.Install())
            else if (!state.Delete() && (state.iFlags & pkgDepCache::ReInstall) == pkgDepCache::ReInstall)
                [reinstalls addObject:name];
            // XXX: move before previous if
            else if (state.Upgrade())
                [upgrades addObject:name];
            else if (state.Downgrade())
                [downgrades addObject:name];
            else if (!state.Delete())
                // XXX: _assert(state.Keep());
                continue;
            else if (special_r(name))
                [issues_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNull null], @"package",
                    [NSArray arrayWithObjects:
                        [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Conflicts", @"relationship",
                            [NSArray arrayWithObjects:
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                    name, @"package",
                                    [NSNull null], @"version",
                                    @"installed", @"reason",
                                nil],
                            nil], @"clauses",
                        nil],
                    nil], @"reasons",
                nil]];
            else {
                if ([package essential])
                    remove = true;
                [removes addObject:name];
            }

            substrate_ |= DepSubstrate(policy->GetCandidateVer(iterator));
            substrate_ |= DepSubstrate(iterator.CurrentVer());
        }

        if (!remove)
            essential_ = nil;
        else if (Advanced_) {
            NSString *parenthetical(UCLocalize("PARENTHETICAL"));

            essential_ = [[[UIAlertView alloc]
                initWithTitle:UCLocalize("REMOVING_ESSENTIALS")
                message:UCLocalize("REMOVING_ESSENTIALS_EX")
                delegate:self
                cancelButtonTitle:[NSString stringWithFormat:parenthetical, UCLocalize("CANCEL_OPERATION"), UCLocalize("SAFE")]
                otherButtonTitles:
                    [NSString stringWithFormat:parenthetical, UCLocalize("FORCE_REMOVAL"), UCLocalize("UNSAFE")],
                nil
            ] autorelease];

            [essential_ setContext:@"remove"];
            [essential_ setNumberOfRows:2];
        } else {
            essential_ = [[[UIAlertView alloc]
                initWithTitle:UCLocalize("UNABLE_TO_COMPLY")
                message:UCLocalize("UNABLE_TO_COMPLY_EX")
                delegate:self
                cancelButtonTitle:UCLocalize("OKAY")
                otherButtonTitles:nil
            ] autorelease];

            [essential_ setContext:@"unable"];
        }

        changes_ = [NSDictionary dictionaryWithObjectsAndKeys:
            installs, @"installs",
            reinstalls, @"reinstalls",
            upgrades, @"upgrades",
            downgrades, @"downgrades",
            removes, @"removes",
        nil];

        sizes_ = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInteger:[database_ fetcher].FetchNeeded()], @"downloading",
            [NSNumber numberWithInteger:[database_ fetcher].PartialPresent()], @"resuming",
        nil];

        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/confirm/", UI_]]];
    } return self;
}

- (UIBarButtonItem *) leftButton {
    return [[[UIBarButtonItem alloc]
        initWithTitle:UCLocalize("CANCEL")
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(cancelButtonClicked)
    ] autorelease];
}

#if !AlwaysReload
- (void) applyRightButton {
    if ([issues_ count] == 0 && ![self isLoading])
        [[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("CONFIRM")
            style:UIBarButtonItemStyleDone
            target:self
            action:@selector(confirmButtonClicked)
        ] autorelease]];
    else
        [[self navigationItem] setRightBarButtonItem:nil];
}
#endif

- (void) cancelButtonClicked {
    [delegate_ cancelAndClear:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#if !AlwaysReload
- (void) confirmButtonClicked {
    if (essential_ != nil)
        [essential_ show];
    else
        [self complete];
}
#endif

@end
/* }}} */

/* Progress Data {{{ */
@interface CydiaProgressData : NSObject {
    _transient id delegate_;

    bool running_;
    float percent_;

    float current_;
    float total_;
    float speed_;

    _H<NSMutableArray> events_;
    _H<NSString> title_;

    _H<NSString> status_;
    _H<NSString> finish_;
}

@end

@implementation CydiaProgressData

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
        @"current",
        @"events",
        @"finish",
        @"percent",
        @"running",
        @"speed",
        @"title",
        @"total",
    nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (id) init {
    if ((self = [super init]) != nil) {
        events_ = [NSMutableArray arrayWithCapacity:32];
    } return self;
}

- (id) delegate {
    return delegate_;
}

- (void) setDelegate:(id)delegate {
    delegate_ = delegate;
}

- (void) setPercent:(float)value {
    percent_ = value;
}

- (NSNumber *) percent {
    return [NSNumber numberWithFloat:percent_];
}

- (void) setCurrent:(float)value {
    current_ = value;
}

- (NSNumber *) current {
    return [NSNumber numberWithFloat:current_];
}

- (void) setTotal:(float)value {
    total_ = value;
}

- (NSNumber *) total {
    return [NSNumber numberWithFloat:total_];
}

- (void) setSpeed:(float)value {
    speed_ = value;
}

- (NSNumber *) speed {
    return [NSNumber numberWithFloat:speed_];
}

- (NSArray *) events {
    return events_;
}

- (void) removeAllEvents {
    [events_ removeAllObjects];
}

- (void) addEvent:(CydiaProgressEvent *)event {
    [events_ addObject:event];
}

- (void) setTitle:(NSString *)text {
    title_ = text;
}

- (NSString *) title {
    return title_;
}

- (void) setFinish:(NSString *)text {
    finish_ = text;
}

- (NSString *) finish {
    return (id) finish_ ?: [NSNull null];
}

- (void) setRunning:(bool)running {
    running_ = running;
}

- (NSNumber *) running {
    return running_ ? (NSNumber *) kCFBooleanTrue : (NSNumber *) kCFBooleanFalse;
}

@end
/* }}} */
/* Progress Controller {{{ */
@interface Cydia_STUB : NSObject
- (void) reloadSpringBoard;
- (void) updateDataAndLoad;

@end
@interface ProgressController : CydiaWebViewController <
    ProgressDelegate
> {
    _transient Database *database_;
    _H<CydiaProgressData, 1> progress_;
    unsigned cancel_;
}

- (id) initWithDatabase:(Database *)database delegate:(id)delegate;

- (void) invoke:(NSInvocation *)invocation withTitle:(NSString *)title;

- (void) setTitle:(NSString *)title;
- (void) setCancellable:(bool)cancellable;

@end

@implementation ProgressController

- (void) dealloc {
    [database_ setProgressDelegate:nil];
    [super dealloc];
}

- (UIBarButtonItem *) leftButton {
    return cancel_ == 1 ? [[[UIBarButtonItem alloc]
        initWithTitle:UCLocalize("CANCEL")
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(cancel)
    ] autorelease] : nil;
}

- (void) updateCancel {
    [super applyLeftButton];
}

- (id) initWithDatabase:(Database *)database delegate:(id)delegate {
    if ((self = [super init]) != nil) {
        database_ = database;
        delegate_ = delegate;

        [database_ setProgressDelegate:self];

        progress_ = [[[CydiaProgressData alloc] init] autorelease];
        [progress_ setDelegate:self];

        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/progress/", UI_]]];

        [scroller_ setBackgroundColor:[UIColor blackColor]];

        [[self navigationItem] setHidesBackButton:YES];

        [self updateCancel];
    } return self;
}

- (void) webView:(WebView *)view didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    [super webView:view didClearWindowObject:window forFrame:frame];
    [window setValue:progress_ forKey:@"cydiaProgress"];
}

- (void) updateProgress {
    [self dispatchEvent:@"CydiaProgressUpdate"];
}

- (void) viewWillAppear:(BOOL)animated {
    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlack];
    [super viewWillAppear:animated];
}

- (void) close {
    UpdateExternalStatus(0);

    if (Finish_ > 1)
        [delegate_ saveState];

    switch (Finish_) {
        case 0:
            [delegate_ returnToCydia];
        break;

        case 1:
            [delegate_ terminateWithSuccess];
            /*if ([delegate_ respondsToSelector:@selector(suspendWithAnimation:)])
                [delegate_ suspendWithAnimation:YES];
            else
                [delegate_ suspend];*/
        break;

        case 2:
            _trace();
            goto reload;

        case 3:
            _trace();
            goto reload;

        reload: {
            UIProgressHUD *hud([delegate_ addProgressHUD]);
            [hud setText:UCLocalize("LOADING")];
            [delegate_ performSelector:@selector(reloadSpringBoard) withObject:nil afterDelay:0.5];
            return;
        }

        case 4:
            _trace();
            if (void (*SBReboot)(mach_port_t) = reinterpret_cast<void (*)(mach_port_t)>(dlsym(RTLD_DEFAULT, "SBReboot")))
                SBReboot(SBSSpringBoardServerPort());
            else
                reboot2(RB_AUTOBOOT);
        break;
    }

    [super close];
}

- (void) setTitle:(NSString *)title {
    [progress_ setTitle:title];
    [self updateProgress];
}

- (UIBarButtonItem *) rightButton {
    return [[progress_ running] boolValue] ? [super rightButton] : [[[UIBarButtonItem alloc]
        initWithTitle:UCLocalize("CLOSE")
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(close)
    ] autorelease];
}

- (void) invoke:(NSInvocation *)invocation withTitle:(NSString *)title {
    UpdateExternalStatus(1);

    [progress_ setRunning:true];
    [self setTitle:title];
    // implicit updateProgress

    SHA1SumValue notifyconf; {
        FileFd file;
        if (!file.Open(NotifyConfig_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            notifyconf = sha1.Result();
        }
    }

    SHA1SumValue springlist; {
        FileFd file;
        if (!file.Open(SpringBoard_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            springlist = sha1.Result();
        }
    }

    if (invocation != nil) {
        [invocation yieldToSelector:@selector(invoke)];
        [self setTitle:@"COMPLETE"];
    }

    if (Finish_ < 4) {
        FileFd file;
        if (!file.Open(NotifyConfig_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            if (!(notifyconf == sha1.Result()))
                Finish_ = 4;
        }
    }

    if (Finish_ < 3) {
        FileFd file;
        if (!file.Open(SpringBoard_, FileFd::ReadOnly))
            _error->Discard();
        else {
            MMap mmap(file, MMap::ReadOnly);
            SHA1Summation sha1;
            sha1.Add(reinterpret_cast<uint8_t *>(mmap.Data()), mmap.Size());
            if (!(springlist == sha1.Result()))
                Finish_ = 3;
        }
    }

    if (Finish_ < 2) {
        if (RestartSubstrate_)
            Finish_ = 2;
    }

    RestartSubstrate_ = false;

    switch (Finish_) {
        case 0: [progress_ setFinish:UCLocalize("RETURN_TO_CYDIA")]; break; /* XXX: Maybe UCLocalize("DONE")? */
        case 1: [progress_ setFinish:UCLocalize("CLOSE_CYDIA")]; break;
        case 2: [progress_ setFinish:UCLocalize("RESTART_SPRINGBOARD")]; break;
        case 3: [progress_ setFinish:UCLocalize("RELOAD_SPRINGBOARD")]; break;
        case 4: [progress_ setFinish:UCLocalize("REBOOT_DEVICE")]; break;
    }

    UpdateExternalStatus(Finish_ == 0 ? 0 : 2);

    [progress_ setRunning:false];
    [self updateProgress];

    [self applyRightButton];
}

- (void) addProgressEvent:(CydiaProgressEvent *)event {
    [progress_ addEvent:event];
    [self updateProgress];
}

- (bool) isProgressCancelled {
    return cancel_ == 2;
}

- (void) cancel {
    cancel_ = 2;
    [self updateCancel];
}

- (void) setCancellable:(bool)cancellable {
    unsigned cancel(cancel_);

    if (!cancellable)
        cancel_ = 0;
    else if (cancel_ == 0)
        cancel_ = 1;

    if (cancel != cancel_)
        [self updateCancel];
}

- (void) setProgressCancellable:(NSNumber *)cancellable {
    [self setCancellable:[cancellable boolValue]];
}

- (void) setProgressPercent:(NSNumber *)percent {
    [progress_ setPercent:[percent floatValue]];
    [self updateProgress];
}

- (void) setProgressStatus:(NSDictionary *)status {
    if (status == nil) {
        [progress_ setCurrent:0];
        [progress_ setTotal:0];
        [progress_ setSpeed:0];
    } else {
        [progress_ setPercent:[[status objectForKey:@"Percent"] floatValue]];

        [progress_ setCurrent:[[status objectForKey:@"Current"] floatValue]];
        [progress_ setTotal:[[status objectForKey:@"Total"] floatValue]];
        [progress_ setSpeed:[[status objectForKey:@"Speed"] floatValue]];
    }

    [self updateProgress];
}

@end
/* }}} */

/* Package Cell {{{ */
@interface PackageCell : CyteTableViewCell <
    CyteTableViewCellDelegate
> {
    _H<UIImage> icon_;
    _H<NSString> name_;
    _H<NSString> description_;
    bool commercial_;
    _H<NSString> source_;
    _H<UIImage> badge_;
    _H<UIImage> placard_;
    bool summarized_;
}

- (PackageCell *) init;
- (void) setPackage:(Package *)package asSummary:(bool)summary;

- (void) drawContentRect:(CGRect)rect;

@end

@implementation PackageCell

- (PackageCell *) init {
    CGRect frame(CGRectMake(0, 0, 320, 74));
    if ((self = [super initWithFrame:frame reuseIdentifier:@"Package"]) != nil) {
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);

        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content addSubview:content_];

        [content_ setDelegate:self];
        [content_ setOpaque:YES];
    } return self;
}

- (NSString *) accessibilityLabel {
    return name_;
}

- (void) setPackage:(Package *)package asSummary:(bool)summary {
    summarized_ = summary;

    icon_ = nil;
    name_ = nil;
    description_ = nil;
    source_ = nil;
    badge_ = nil;
    placard_ = nil;

    if (package == nil)
        [content_ setBackgroundColor:[UIColor whiteColor]];
    else {
        [package parse];

        Source *source = [package source];

        icon_ = [package icon];

        if (NSString *name = [package name])
            name_ = [NSString stringWithString:name];

        if (NSString *description = [package shortDescription])
            description_ = [NSString stringWithString:description];

        commercial_ = [package isCommercial];

        NSString *label = nil;
        bool trusted = false;

        if (source != nil) {
            label = [source label];
            trusted = [source trusted];
        } else if ([[package id] isEqualToString:@"firmware"])
            label = UCLocalize("APPLE");
        else
            label = [NSString stringWithFormat:UCLocalize("SLASH_DELIMITED"), UCLocalize("UNKNOWN"), UCLocalize("LOCAL")];

        NSString *from(label);

        NSString *section = [package simpleSection];
        if (section != nil && ![section isEqualToString:label]) {
            section = [[NSBundle mainBundle] localizedStringForKey:section value:nil table:@"Sections"];
            from = [NSString stringWithFormat:UCLocalize("PARENTHETICAL"), from, section];
        }

        source_ = [NSString stringWithFormat:UCLocalize("FROM"), from];

        if (NSString *purpose = [package primaryPurpose])
            badge_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/Purposes/%@.png", App_, purpose]];

        UIColor *color;
        NSString *placard;

        if (NSString *mode = [package mode]) {
            if ([mode isEqualToString:@"REMOVE"] || [mode isEqualToString:@"PURGE"]) {
                color = RemovingColor_;
                placard = @"removing";
            } else {
                color = InstallingColor_;
                placard = @"installing";
            }
        } else {
            color = [UIColor whiteColor];

            if ([package installed] != nil)
                placard = @"installed";
            else
                placard = nil;
        }

        [content_ setBackgroundColor:color];

        if (placard != nil)
            placard_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/%@.png", App_, placard]];
    }

    [self setNeedsDisplay];
    [content_ setNeedsDisplay];
}

- (void) drawSummaryContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width([self bounds].size.width);

    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];

        while (rect.size.width > 16 || rect.size.height > 16) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }

        rect.origin.x = 19 - rect.size.width / 2;
        rect.origin.y = 19 - rect.size.height / 2;

        [icon_ drawInRect:Retina(rect)];
    }

    if (badge_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) badge_ size];

        rect.size.width /= 4;
        rect.size.height /= 4;

        rect.origin.x = 25 - rect.size.width / 2;
        rect.origin.y = 25 - rect.size.height / 2;

        [badge_ drawInRect:Retina(rect)];
    }

    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor(White_);

    if (!highlighted)
        UISetColor(commercial_ ? Purple_ : Black_);
    [name_ drawAtPoint:CGPointMake(36, 8) forWidth:(width - (placard_ == nil ? 68 : 94)) withFont:Font18Bold_ lineBreakMode:NSLineBreakByTruncatingTail];

    if (placard_ != nil)
        [placard_ drawAtPoint:CGPointMake(width - 52, 11)];
}

- (void) drawNormalContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width([self bounds].size.width);

    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];

        while (rect.size.width > 32 || rect.size.height > 32) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }

        rect.origin.x = 25 - rect.size.width / 2;
        rect.origin.y = 25 - rect.size.height / 2;

        [icon_ drawInRect:Retina(rect)];
    }

    if (badge_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) badge_ size];

        rect.size.width /= 2;
        rect.size.height /= 2;

        rect.origin.x = 36 - rect.size.width / 2;
        rect.origin.y = 36 - rect.size.height / 2;

        [badge_ drawInRect:Retina(rect)];
    }

    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor(White_);

    if (!highlighted)
        UISetColor(commercial_ ? Purple_ : Black_);
    [name_ drawAtPoint:CGPointMake(48, 8) forWidth:(width - (placard_ == nil ? 80 : 106)) withFont:Font18Bold_ lineBreakMode:NSLineBreakByTruncatingTail];
    [source_ drawAtPoint:CGPointMake(58, 29) forWidth:(width - 95) withFont:Font12_ lineBreakMode:NSLineBreakByTruncatingTail];

    if (!highlighted)
        UISetColor(commercial_ ? Purplish_ : Gray_);
    [description_ drawAtPoint:CGPointMake(12, 46) forWidth:(width - 46) withFont:Font14_ lineBreakMode:NSLineBreakByTruncatingTail];

    if (placard_ != nil)
        [placard_ drawAtPoint:CGPointMake(width - 52, 9)];
}

- (void) drawContentRect:(CGRect)rect {
    if (summarized_)
        [self drawSummaryContentRect:rect];
    else
        [self drawNormalContentRect:rect];
}

@end
/* }}} */
/* Section Cell {{{ */
@interface SectionCell : CyteTableViewCell <
    CyteTableViewCellDelegate
> {
    _H<NSString> basic_;
    _H<NSString> section_;
    _H<NSString> name_;
    _H<NSString> count_;
    _H<UIImage> icon_;
    _H<UISwitch> switch_;
    BOOL editing_;
}

- (void) setSection:(Section *)section editing:(BOOL)editing;

@end

@implementation SectionCell

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) != nil) {
        icon_ = [UIImage imageNamed:@"folder.png"];
        // XXX: this initial frame is wrong, but is fixed later
        switch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(218, 9, 60, 25)] autorelease];
        [switch_ addTarget:self action:@selector(onSwitch:) forEvents:UIControlEventValueChanged];

        UIView *content([self contentView]);
        CGRect bounds([content bounds]);

        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content addSubview:content_];
        [content_ setBackgroundColor:[UIColor whiteColor]];

        [content_ setDelegate:self];
    } return self;
}

- (void) onSwitch:(id)sender {
    NSMutableDictionary *metadata([Sections_ objectForKey:basic_]);
    if (metadata == nil) {
        metadata = [NSMutableDictionary dictionaryWithCapacity:2];
        [Sections_ setObject:metadata forKey:basic_];
    }

    [metadata setObject:[NSNumber numberWithBool:([switch_ isOn] == NO)] forKey:@"Hidden"];
}

- (void) setSection:(Section *)section editing:(BOOL)editing {
    if (editing != editing_) {
        if (editing_)
            [switch_ removeFromSuperview];
        else
            [self addSubview:switch_];
        editing_ = editing;
    }

    basic_ = nil;
    section_ = nil;
    name_ = nil;
    count_ = nil;

    if (section == nil) {
        name_ = UCLocalize("ALL_PACKAGES");
        count_ = nil;
    } else {
        basic_ = [section name];
        section_ = [section localized];

        name_  = section_ == nil || [section_ length] == 0 ? UCLocalize("NO_SECTION") : (NSString *) section_;
        count_ = [NSString stringWithFormat:@"%zd", [section count]];

        if (editing_)
            [switch_ setOn:(isSectionVisible(basic_) ? 1 : 0) animated:NO];
    }

    [self setAccessoryType:editing ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator];
    [self setSelectionStyle:editing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue];

    [content_ setNeedsDisplay];
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];

    CGRect rect([switch_ frame]);
    [switch_ setFrame:CGRectMake(frame.size.width - rect.size.width - 9, 9, rect.size.width, rect.size.height)];
}

- (NSString *) accessibilityLabel {
    return name_;
}

- (void) drawContentRect:(CGRect)rect {
    bool highlighted(highlighted_ && !editing_);

    [icon_ drawInRect:CGRectMake(7, 7, 32, 32)];

    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor(White_);

    float width(rect.size.width);
    if (editing_)
        width -= 9 + [switch_ frame].size.width;

    if (!highlighted)
        UISetColor(Black_);
    [name_ drawAtPoint:CGPointMake(48, 12) forWidth:(width - 58) withFont:Font18_ lineBreakMode:NSLineBreakByTruncatingTail];

    CGSize size = [count_ sizeWithFont:Font14_];

    UISetColor(Folder_);
    if (count_ != nil)
        [count_ drawAtPoint:CGPointMake(Retina(10 + (30 - size.width) / 2), 18) withFont:Font12Bold_];
}

@end
/* }}} */

/* File Table {{{ */
@interface FileTable : CyteViewController <
    UITableViewDataSource,
    UITableViewDelegate
> {
    _transient Database *database_;
    _H<Package> package_;
    _H<NSString> name_;
    _H<NSMutableArray> files_;
    _H<UITableView, 2> list_;
}

- (id) initWithDatabase:(Database *)database;
- (void) setPackage:(Package *)package;

@end

@implementation FileTable

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return files_ == nil ? 0 : [files_ count];
}

/*- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 24.0f;
}*/

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];
        [cell setFont:[UIFont systemFontOfSize:16]];
    }
    [cell setText:[files_ objectAtIndex:indexPath.row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    return cell;
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@/files", [package_ id]]];
}

- (void) loadView {
    list_ = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
    [list_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [list_ setRowHeight:24.0f];
    [(UITableView *) list_ setDataSource:self];
    [list_ setDelegate:self];
    [self setView:list_];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    [[self navigationItem] setTitle:UCLocalize("INSTALLED_FILES")];
}

- (void) releaseSubviews {
    list_ = nil;

    package_ = nil;
    files_ = nil;

    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;
    } return self;
}

- (void) setPackage:(Package *)package {
    package_ = nil;
    name_ = nil;

    files_ = [NSMutableArray arrayWithCapacity:32];

    if (package != nil) {
        package_ = package;
        name_ = [package id];

        if (NSArray *files = [package files])
            [files_ addObjectsFromArray:files];

        if ([files_ count] != 0) {
            if ([[files_ objectAtIndex:0] isEqualToString:@"/."])
                [files_ removeObjectAtIndex:0];
            [files_ sortUsingSelector:@selector(compareByPath:)];

            NSMutableArray *stack = [NSMutableArray arrayWithCapacity:8];
            [stack addObject:@"/"];

            for (int i(0), e([files_ count]); i != e; ++i) {
                NSString *file = [files_ objectAtIndex:i];
                while (![file hasPrefix:[stack lastObject]])
                    [stack removeLastObject];
                NSString *directory = [stack lastObject];
                [stack addObject:[file stringByAppendingString:@"/"]];
                [files_ replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%*s%@",
                    ([stack count] - 2) * 3, "",
                    [file substringFromIndex:[directory length]]
                ]];
            }
        }
    }

    [list_ reloadData];
}

- (void) reloadData {
    [super reloadData];

    [self setPackage:[database_ packageWithName:name_]];
}

@end
/* }}} */
/* Package Controller {{{ */
@interface CYPackageController : CydiaWebViewController <
    UIActionSheetDelegate
> {
    _transient Database *database_;
    _H<Package> package_;
    _H<NSString> name_;
    bool commercial_;
    std::vector<std::pair<_H<NSString>, _H<NSString>>> buttons_;
    _H<UIActionSheet> sheet_;
    _H<UIBarButtonItem> button_;
    _H<NSArray> versions_;
}

- (id) initWithDatabase:(Database *)database forPackage:(NSString *)name withReferrer:(NSString *)referrer;

@end

@implementation CYPackageController

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@", (id) name_]];
}

- (void) _clickButtonWithPackage:(Package *)package {
    [delegate_ installPackage:package];
}

- (void) _clickButtonWithName:(NSString *)name {
    if ([name isEqualToString:@"CLEAR"])
        return [delegate_ clearPackage:package_];
    else if ([name isEqualToString:@"REMOVE"])
        return [delegate_ removePackage:package_];
    else if ([name isEqualToString:@"DOWNGRADE"]) {
        sheet_ = [[[UIActionSheet alloc]
            initWithTitle:nil
            delegate:self
            cancelButtonTitle:nil
            destructiveButtonTitle:nil
            otherButtonTitles:nil
        ] autorelease];

        for (Package *version in (id) versions_)
            [sheet_ addButtonWithTitle:[version latest]];
        [sheet_ setContext:@"version"];

        [delegate_ showActionSheet:sheet_ fromItem:[[self navigationItem] rightBarButtonItem]];
        return;
    }

    else if ([name isEqualToString:@"INSTALL"]);
    else if ([name isEqualToString:@"REINSTALL"]);
    else if ([name isEqualToString:@"UPGRADE"]);
    else _assert(false);

    [delegate_ installPackage:package_];
}

- (void) actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)button {
    NSString *context([sheet context]);
    if (sheet_ == sheet)
        sheet_ = nil;

    if ([context isEqualToString:@"modify"]) {
        if (button != [sheet cancelButtonIndex]) {
            if (IsWildcat_)
                [self performSelector:@selector(_clickButtonWithName:) withObject:buttons_[button].first afterDelay:0];
            else
                [self _clickButtonWithName:buttons_[button].first];
        }

        [sheet dismissWithClickedButtonIndex:button animated:YES];
    } else if ([context isEqualToString:@"version"]) {
        if (button != [sheet cancelButtonIndex]) {
            Package *version([versions_ objectAtIndex:button]);
            if (IsWildcat_)
                [self performSelector:@selector(_clickButtonWithPackage:) withObject:version afterDelay:0];
            else
                [self _clickButtonWithPackage:version];
        }

        [sheet dismissWithClickedButtonIndex:button animated:YES];
    }
}

- (bool) _allowJavaScriptPanel {
    return commercial_;
}

#if !AlwaysReload
- (void) _customButtonClicked {
    size_t count(buttons_.size());
    if (count == 0)
        return;

    if (count == 1)
        [self _clickButtonWithName:buttons_[0].first];
    else {
        NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:count];
        for (const auto &button : buttons_)
            [buttons addObject:button.second];

        sheet_ = [[[UIActionSheet alloc]
            initWithTitle:nil
            delegate:self
            cancelButtonTitle:nil
            destructiveButtonTitle:nil
            otherButtonTitles:nil
        ] autorelease];

        for (NSString *button in buttons)
            [sheet_ addButtonWithTitle:button];
        [sheet_ setContext:@"modify"];

        [delegate_ showActionSheet:sheet_ fromItem:[[self navigationItem] rightBarButtonItem]];
    }
}

- (void) reloadButtonClicked {
    if (commercial_ && function_ == nil && [package_ uninstalled])
        return;
    [self customButtonClicked];
}

- (void) applyLoadingTitle {
    // Don't show "Loading" as the title. Ever.
}

- (UIBarButtonItem *) rightButton {
    return button_;
}
#endif

- (void) setPageColor:(UIColor *)color {
    return [super setPageColor:nil];
}

- (id) initWithDatabase:(Database *)database forPackage:(NSString *)name withReferrer:(NSString *)referrer {
    if ((self = [super init]) != nil) {
        database_ = database;
        name_ = name == nil ? @"" : [NSString stringWithString:name];
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/package/%@", UI_, (id) name_]] withReferrer:referrer];
    } return self;
}

- (void) reloadData {
    [super reloadData];

    [sheet_ dismissWithClickedButtonIndex:[sheet_ cancelButtonIndex] animated:YES];
    sheet_ = nil;

    package_ = [database_ packageWithName:name_];
    versions_ = [package_ downgrades];

    buttons_.clear();

    if (package_ != nil) {
        [(Package *) package_ parse];

        commercial_ = [package_ isCommercial];

        if ([package_ mode] != nil)
            buttons_.push_back(std::make_pair(@"CLEAR", UCLocalize("CLEAR")));
        if ([package_ source] == nil);
        else if ([package_ upgradableAndEssential:NO])
            buttons_.push_back(std::make_pair(@"UPGRADE", UCLocalize("UPGRADE")));
        else if ([package_ uninstalled])
            buttons_.push_back(std::make_pair(@"INSTALL", UCLocalize("INSTALL")));
        else
            buttons_.push_back(std::make_pair(@"REINSTALL", UCLocalize("REINSTALL")));
        if (![package_ uninstalled])
            buttons_.push_back(std::make_pair(@"REMOVE", UCLocalize("REMOVE")));
        if ([versions_ count] != 0)
            buttons_.push_back(std::make_pair(@"DOWNGRADE", UCLocalize("DOWNGRADE")));
    }

    NSString *title;
    switch (buttons_.size()) {
        case 0: title = nil; break;
        case 1: title = buttons_[0].second; break;
        default: title = UCLocalize("MODIFY"); break;
    }

    button_ = [[[UIBarButtonItem alloc]
        initWithTitle:title
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(customButtonClicked)
    ] autorelease];
}

- (bool) isLoading {
    return commercial_ ? [super isLoading] : false;
}

@end
/* }}} */

/* Package List Controller {{{ */
@interface PackageListController : CyteViewController <
    UITableViewDataSource,
    UITableViewDelegate
> {
    _transient Database *database_;
    unsigned era_;
    _H<NSArray> packages_;
    _H<NSArray> sections_;
    _H<UITableView, 2> list_;

    _H<NSArray> thumbs_;
    std::vector<NSInteger> offset_;

    _H<NSString> title_;
    unsigned reloading_;
}

- (id) initWithDatabase:(Database *)database title:(NSString *)title;
- (void) setDelegate:(id)delegate;
- (void) resetCursor;
- (void) clearData;

- (NSArray *) sectionsForPackages:(NSMutableArray *)packages;

@end

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
/* }}} */
/* Filtered Package List Controller {{{ */
typedef Function<bool, Package *> PackageFilter;
typedef Function<void, NSMutableArray *> PackageSorter;
@interface FilteredPackageListController : PackageListController {
    PackageFilter filter_;
    PackageSorter sorter_;
}

- (id) initWithDatabase:(Database *)database title:(NSString *)title filter:(PackageFilter)filter;

- (void) setFilter:(PackageFilter)filter;
- (void) setSorter:(PackageSorter)sorter;

@end

@implementation FilteredPackageListController

- (void) setFilter:(PackageFilter)filter {
@synchronized (self) {
    filter_ = filter;
} }

- (void) setSorter:(PackageSorter)sorter {
@synchronized (self) {
    sorter_ = sorter;
} }

- (NSMutableArray *) _reloadPackages {
@synchronized (database_) {
    era_ = [database_ era];

    NSArray *packages([database_ packages]);
    NSMutableArray *filtered([NSMutableArray arrayWithCapacity:[packages count]]);

    PackageFilter filter;
    PackageSorter sorter;

    @synchronized (self) {
        filter = filter_;
        sorter = sorter_;
    }

    _profile(PackageTable$reloadData$Filter)
        for (Package *package in packages)
            if (filter(package))
                [filtered addObject:package];
    _end

    if (sorter)
        sorter(filtered);
    return filtered;
} }

- (id) initWithDatabase:(Database *)database title:(NSString *)title filter:(PackageFilter)filter {
    if ((self = [super initWithDatabase:database title:title]) != nil) {
        [self setFilter:filter];
    } return self;
}

@end
/* }}} */

/* Home Controller {{{ */
@interface HomeController : CydiaWebViewController {
    CFRunLoopRef runloop_;
    SCNetworkReachabilityRef reachability_;
}

@end

@implementation HomeController

static void HomeControllerReachabilityCallback(SCNetworkReachabilityRef reachability, SCNetworkReachabilityFlags flags, void *info) {
    [(HomeController *) info dispatchEvent:@"CydiaReachabilityCallback"];
}

- (id) init {
    if ((self = [super init]) != nil) {
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/home/", UI_]]];
        [self reloadData];

        reachability_ = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "cydia.saurik.com");
        if (reachability_ != NULL) {
            SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
            SCNetworkReachabilitySetCallback(reachability_, HomeControllerReachabilityCallback, &context);

            CFRunLoopRef runloop(CFRunLoopGetCurrent());
            if (SCNetworkReachabilityScheduleWithRunLoop(reachability_, runloop, kCFRunLoopDefaultMode))
                runloop_ = runloop;
        }
    } return self;
}

- (void) dealloc {
    if (reachability_ != NULL && runloop_ != NULL)
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability_, runloop_, kCFRunLoopDefaultMode);
    [super dealloc];
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://home"];
}

- (void) aboutButtonClicked {
    UIAlertView *alert([[[UIAlertView alloc] init] autorelease]);

    [alert setTitle:UCLocalize("ABOUT_CYDIA")];
    [alert addButtonWithTitle:UCLocalize("CLOSE")];
    [alert setCancelButtonIndex:0];

    [alert setMessage:
        @"Copyright \u00a9 2008-2015\n"
        "SaurikIT, LLC\n"
        "\n"
        "Jay Freeman (saurik)\n"
        "saurik@saurik.com\n"
        "http://www.saurik.com/"
    ];

    [alert show];
}

- (UIBarButtonItem *) leftButton {
    return [[[UIBarButtonItem alloc]
        initWithTitle:UCLocalize("ABOUT")
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(aboutButtonClicked)
    ] autorelease];
}

@end
/* }}} */

/* Cydia Navigation Controller Interface {{{ */
@interface UINavigationController (Cydia)

- (NSArray *) navigationURLCollection;
- (void) unloadData;

@end
/* }}} */

/* Cydia Tab Bar Controller {{{ */
@interface CydiaTabBarController : CyteTabBarController <
    UITabBarControllerDelegate,
    FetchDelegate
> {
    _transient Database *database_;

    _H<UIActivityIndicatorView> indicator_;

    bool updating_;
    // XXX: ok, "updatedelegate_"?...
    _transient NSObject<CydiaDelegate> *updatedelegate_;
}

- (NSArray *) navigationURLCollection;
- (void) beginUpdate;
- (BOOL) updating;

@end

@implementation CydiaTabBarController

- (NSArray *) navigationURLCollection {
    NSMutableArray *items([NSMutableArray array]);

    // XXX: Should this deal with transient view controllers?
    for (id navigation in [self viewControllers]) {
        NSArray *stack = [navigation performSelector:@selector(navigationURLCollection)];
        if (stack != nil)
            [items addObject:stack];
    }

    return items;
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;
        [self setDelegate:self];

        indicator_ = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteTiny] autorelease];
        [indicator_ setOrigin:CGPointMake(kCFCoreFoundationVersionNumber >= 800 ? 2 : 4, 2)];

        [[self view] setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    } return self;
}

- (void) beginUpdate {
    if (updating_)
        return;

    UIViewController *controller([[self viewControllers] objectAtIndex:1]);
    UITabBarItem *item([controller tabBarItem]);

    [item setBadgeValue:@""];
    UIView *badge(MSHookIvar<UIView *>([item view], "_badge"));

    [indicator_ startAnimating];
    [badge addSubview:indicator_];

    [updatedelegate_ retainNetworkActivityIndicator];
    updating_ = true;

    [NSThread
        detachNewThreadSelector:@selector(performUpdate)
        toTarget:self
        withObject:nil
    ];
}

- (void) performUpdate {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    SourceStatus status(self, database_);
    [database_ updateWithStatus:status];

    [self
        performSelectorOnMainThread:@selector(completeUpdate)
        withObject:nil
        waitUntilDone:NO
    ];

    [pool release];
}

- (void) stopUpdateWithSelector:(SEL)selector {
    updating_ = false;
    [updatedelegate_ releaseNetworkActivityIndicator];

    UIViewController *controller([[self viewControllers] objectAtIndex:1]);
    [[controller tabBarItem] setBadgeValue:nil];

    [indicator_ removeFromSuperview];
    [indicator_ stopAnimating];

    [updatedelegate_ performSelector:selector withObject:nil afterDelay:0];
}

- (void) completeUpdate {
    if (!updating_)
        return;
    [self stopUpdateWithSelector:@selector(reloadData)];
}

- (void) cancelUpdate {
    [self stopUpdateWithSelector:@selector(updateDataAndLoad)];
}

- (void) cancelPressed {
    [self cancelUpdate];
}

- (BOOL) updating {
    return updating_;
}

- (bool) isSourceCancelled {
    return !updating_;
}

- (void) startSourceFetch:(NSString *)uri {
}

- (void) stopSourceFetch:(NSString *)uri {
}

- (void) setUpdateDelegate:(id)delegate {
    updatedelegate_ = delegate;
}

@end
/* }}} */

/* Cydia Navigation Controller Implementation {{{ */
@implementation UINavigationController (Cydia)

- (NSArray *) navigationURLCollection {
    NSMutableArray *stack([NSMutableArray array]);

    for (CyteViewController *controller in [self viewControllers]) {
        NSString *url = [[controller navigationURL] absoluteString];
        if (url != nil)
            [stack addObject:url];
    }

    return stack;
}

- (void) reloadData {
    [super reloadData];

    UIViewController *visible([self visibleViewController]);
    if (visible != nil)
        [visible reloadData];

    // on the iPad, this view controller is ALSO visible. :(
    if (IsWildcat_)
        if (UIViewController *modal = [self modalViewController])
            if ([modal modalPresentationStyle] == UIModalPresentationFormSheet)
                if (UIViewController *top = [self topViewController])
                    if (top != visible)
                        [top reloadData];
}

- (void) unloadData {
    for (CyteViewController *page in [self viewControllers])
        [page unloadData];

    [super unloadData];
}

@end
/* }}} */

/* Cydia:// Protocol {{{ */
@interface CydiaURLProtocol : NSURLProtocol {
}

@end

@implementation CydiaURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request {
    NSURL *url([request URL]);
    if (url == nil)
        return NO;

    NSString *scheme([[url scheme] lowercaseString]);
    if (scheme != nil && [scheme isEqualToString:@"cydia"])
        return YES;
    if ([[url absoluteString] hasPrefix:@"about:cydia-"])
        return YES;

    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) _returnPNGWithImage:(UIImage *)icon forRequest:(NSURLRequest *)request {
    id<NSURLProtocolClient> client([self client]);
    if (icon == nil)
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil]];
    else {
        NSData *data(UIImagePNGRepresentation(icon));

        NSURLResponse *response([[[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"image/png" expectedContentLength:-1 textEncodingName:nil] autorelease]);
        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [client URLProtocol:self didLoadData:data];
        [client URLProtocolDidFinishLoading:self];
    }
}

- (void) startLoading {
    id<NSURLProtocolClient> client([self client]);
    NSURLRequest *request([self request]);

    NSURL *url([request URL]);
    NSString *href([url absoluteString]);
    NSString *scheme([[url scheme] lowercaseString]);

    NSString *path;

    if ([scheme isEqualToString:@"cydia"])
        path = [href substringFromIndex:8];
    else if ([scheme isEqualToString:@"about"])
        path = [href substringFromIndex:12];
    else _assert(false);

    NSRange slash([path rangeOfString:@"/"]);

    NSString *command;
    if (slash.location == NSNotFound) {
        command = path;
        path = nil;
    } else {
        command = [path substringToIndex:slash.location];
        path = [path substringFromIndex:(slash.location + 1)];
    }

    Database *database([Database sharedInstance]);

    if (false);
    else if ([command isEqualToString:@"application-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        UIImage *icon(nil);

        if (icon == nil && $SBSCopyIconImagePNGDataForDisplayIdentifier != NULL) {
            NSData *data([$SBSCopyIconImagePNGDataForDisplayIdentifier(path) autorelease]);
            icon = [UIImage imageWithData:data];
        }

        if (icon == nil)
            if (NSString *file = SBSCopyIconImagePathForDisplayIdentifier(path))
                icon = [UIImage imageAtPath:file];

        if (icon == nil)
            icon = [UIImage imageNamed:@"unknown.png"];

        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"package-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        Package *package([database packageWithName:path]);
        if (package == nil)
            goto fail;
        [package parse];
        UIImage *icon([package icon]);
        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"uikit-image"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *icon(_UIImageWithName(path));
        [self _returnPNGWithImage:icon forRequest:request];
    } else if ([command isEqualToString:@"section-icon"]) {
        if (path == nil)
            goto fail;
        path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *icon([UIImage imageAtPath:[NSString stringWithFormat:@"%@/Sections/%@.png", App_, [path stringByReplacingOccurrencesOfString:@" " withString:@"_"]]]);
        if (icon == nil)
            icon = [UIImage imageNamed:@"unknown.png"];
        [self _returnPNGWithImage:icon forRequest:request];
    } else fail: {
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
    }
}

- (void) stopLoading {
}

@end
/* }}} */

/* Section Controller {{{ */
@interface SectionController : FilteredPackageListController {
    _H<NSString> key_;
    _H<NSString> section_;
}

- (id) initWithDatabase:(Database *)database source:(Source *)source section:(NSString *)section;

@end

@implementation SectionController

- (NSURL *) referrerURL {
    NSString *name(section_);
    name = name ?: @"*";
    NSString *key(key_);
    key = key ?: @"*";
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/sections/%@/%@", UI_, [key stringByAddingPercentEscapesIncludingReserved], [name stringByAddingPercentEscapesIncludingReserved]]];
}

- (NSURL *) navigationURL {
    NSString *name(section_);
    name = name ?: @"*";
    NSString *key(key_);
    key = key ?: @"*";
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://sections/%@/%@", [key stringByAddingPercentEscapesIncludingReserved], [name stringByAddingPercentEscapesIncludingReserved]]];
}

- (id) initWithDatabase:(Database *)database source:(Source *)source section:(NSString *)section {
    NSString *title;
    if (section == nil)
        title = UCLocalize("ALL_PACKAGES");
    else if (![section isEqual:@""])
        title = [[NSBundle mainBundle] localizedStringForKey:Simplify(section) value:nil table:@"Sections"];
    else
        title = UCLocalize("NO_SECTION");

    if ((self = [super initWithDatabase:database title:title]) != nil) {
        key_ = [source key];
        section_ = section;
    } return self;
}

- (void) reloadData {
    Source *source([database_ sourceWithKey:key_]);
    _H<NSString> name(section_);

    [self setFilter:[=](Package *package) {
        NSString *section([package section]);

        return (
            name == nil ||
            (section == nil && [name length] == 0) ||
            [name isEqualToString:section]
        ) && (
            source == nil ||
            [package source] == source
        ) && [package visible];
    }];

    [super reloadData];
}

@end
/* }}} */
/* Sections Controller {{{ */
@interface SectionsController : CyteViewController <
    UITableViewDataSource,
    UITableViewDelegate
> {
    _transient Database *database_;
    _H<NSString> key_;
    _H<NSMutableArray> sections_;
    _H<NSMutableArray> filtered_;
    _H<UITableView, 2> list_;
}

- (id) initWithDatabase:(Database *)database source:(Source *)source;
- (void) editButtonClicked;

@end

@implementation SectionsController

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://sources/%@", [key_ stringByAddingPercentEscapesIncludingReserved]]];
}

- (Source *) source {
    if (key_ == nil)
        return nil;
    return [database_ sourceWithKey:key_];
}

- (void) updateNavigationItem {
    [[self navigationItem] setTitle:[self isEditing] ? UCLocalize("SECTION_VISIBILITY") : UCLocalize("SECTIONS")];
    if ([sections_ count] == 0) {
        [[self navigationItem] setRightBarButtonItem:nil];
    } else {
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:([self isEditing] ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit)
            target:self
            action:@selector(editButtonClicked)
        ] animated:([[self navigationItem] rightBarButtonItem] != nil)];
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (editing)
        [list_ reloadData];
    else
        [delegate_ updateData];

    [self updateNavigationItem];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [list_ deselectRowAtIndexPath:[list_ indexPathForSelectedRow] animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setEditing:NO];
}

- (Section *) sectionAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = nil;
    int index = [indexPath row];
    if (![self isEditing]) {
        index -= 1;
        if (index >= 0)
            section = [filtered_ objectAtIndex:index];
    } else {
        section = [sections_ objectAtIndex:index];
    }
    return section;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isEditing])
        return [sections_ count];
    else
        return [filtered_ count] + 1;
}

/*- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45.0f;
}*/

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"SectionCell";

    SectionCell *cell = (SectionCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil)
        cell = [[[SectionCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];

    [cell setSection:[self sectionAtIndexPath:indexPath] editing:[self isEditing]];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isEditing])
        return;

    Section *section = [self sectionAtIndexPath:indexPath];

    SectionController *controller = [[[SectionController alloc]
        initWithDatabase:database_
        source:[self source]
        section:[section name]
    ] autorelease];
    [controller setDelegate:delegate_];

    [[self navigationController] pushViewController:controller animated:YES];
}

- (void) loadView {
    list_ = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
    [list_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [list_ setRowHeight:46];
    [(UITableView *) list_ setDataSource:self];
    [list_ setDelegate:self];
    [self setView:list_];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    [[self navigationItem] setTitle:UCLocalize("SECTIONS")];
}

- (void) releaseSubviews {
    list_ = nil;

    sections_ = nil;
    filtered_ = nil;

    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database source:(Source *)source {
    if ((self = [super init]) != nil) {
        database_ = database;
        key_ = [source key];
    } return self;
}

- (void) reloadData {
    [super reloadData];

    NSArray *packages = [database_ packages];

    sections_ = [NSMutableArray arrayWithCapacity:16];
    filtered_ = [NSMutableArray arrayWithCapacity:16];

    NSMutableDictionary *sections([NSMutableDictionary dictionaryWithCapacity:32]);

    Source *source([self source]);

    _trace();
    for (Package *package in packages) {
        if (source != nil && [package source] != source)
            continue;

        NSString *name([package section]);
        NSString *key(name == nil ? @"" : name);

        Section *section;

        _profile(SectionsView$reloadData$Section)
            section = [sections objectForKey:key];
            if (section == nil) {
                _profile(SectionsView$reloadData$Section$Allocate)
                    section = [[[Section alloc] initWithName:key localize:YES] autorelease];
                    [sections setObject:section forKey:key];
                _end
            }
        _end

        [section addToCount];

        _profile(SectionsView$reloadData$Filter)
            if (![package visible])
                continue;
        _end

        [section addToRow];
    }
    _trace();

    [sections_ addObjectsFromArray:[sections allValues]];

    [sections_ sortUsingSelector:@selector(compareByLocalized:)];

    for (Section *section in (id) sections_) {
        size_t count([section row]);
        if (count == 0)
            continue;

        section = [[[Section alloc] initWithName:[section name] localized:[section localized]] autorelease];
        [section setCount:count];
        [filtered_ addObject:section];
    }

    [self updateNavigationItem];
    [list_ reloadData];
    _trace();
}

- (void) editButtonClicked {
    [self setEditing:![self isEditing] animated:YES];
}

@end
/* }}} */

/* Changes Controller {{{ */
@interface ChangesController : FilteredPackageListController {
    unsigned upgrades_;
}

- (id) initWithDatabase:(Database *)database;

@end

@implementation ChangesController

- (NSURL *) referrerURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/changes/", UI_]];
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://changes"];
}

- (Package *) packageAtIndexPath:(NSIndexPath *)path {
@synchronized (database_) {
    if ([database_ era] != era_)
        return nil;

    NSUInteger sectionIndex([path section]);
    if (sectionIndex >= [sections_ count])
        return nil;
    Section *section([sections_ objectAtIndex:sectionIndex]);
    NSInteger row([path row]);
    return [[[packages_ objectAtIndex:([section row] + row)] retain] autorelease];
} }

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button {
    NSString *context([alert context]);

    if ([context isEqualToString:@"norefresh"])
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void) setLeftBarButtonItem {
    if ([delegate_ updating])
        [[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("CANCEL")
            style:UIBarButtonItemStyleDone
            target:self
            action:@selector(cancelButtonClicked)
        ] autorelease] animated:YES];
    else
        [[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("REFRESH")
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(refreshButtonClicked)
        ] autorelease] animated:YES];
}

- (void) refreshButtonClicked {
    if ([delegate_ requestUpdate])
        [self setLeftBarButtonItem];
}

- (void) cancelButtonClicked {
    [delegate_ cancelUpdate];
}

- (void) upgradeButtonClicked {
    [delegate_ distUpgrade];
    [[self navigationItem] setRightBarButtonItem:nil animated:YES];
}

- (bool) shouldYield {
    return true;
}

- (bool) shouldBlock {
    return true;
}

- (void) useFilter {
@synchronized (self) {
    [self setFilter:[](Package *package) {
        return [package upgradableAndEssential:YES] || [package visible];
    }];

    [self setSorter:[](NSMutableArray *packages) {
        [packages radixSortUsingFunction:reinterpret_cast<MenesRadixSortFunction>(&PackageChangesRadix) withContext:NULL];
    }];
} }

- (id) initWithDatabase:(Database *)database {
    if ((self = [super initWithDatabase:database title:UCLocalize("CHANGES")]) != nil) {
        [self useFilter];
    } return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self setLeftBarButtonItem];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setLeftBarButtonItem];
}

- (void) reloadData {
    [self setLeftBarButtonItem];
    [super reloadData];
}

- (NSArray *) sectionsForPackages:(NSMutableArray *)packages {
    NSMutableArray *sections([NSMutableArray arrayWithCapacity:16]);

    Section *upgradable = [[[Section alloc] initWithName:UCLocalize("AVAILABLE_UPGRADES") localize:NO] autorelease];
    Section *ignored = nil;
    Section *section = nil;
    time_t last = 0;

    upgrades_ = 0;
    bool unseens = false;

    CFDateFormatterRef formatter(CFDateFormatterCreate(NULL, Locale_, kCFDateFormatterMediumStyle, kCFDateFormatterMediumStyle));

    for (size_t offset = 0, count = [packages count]; offset != count; ++offset) {
        Package *package = [packages objectAtIndex:offset];

        BOOL uae = [package upgradableAndEssential:YES];

        if (!uae) {
            unseens = true;
            time_t seen([package seen]);

            if (section == nil || last != seen) {
                last = seen;

                NSString *name;
                name = (NSString *) CFDateFormatterCreateStringWithDate(NULL, formatter, (CFDateRef) [NSDate dateWithTimeIntervalSince1970:seen]);
                [name autorelease];

                _profile(ChangesController$reloadData$Allocate)
                    name = [NSString stringWithFormat:UCLocalize("NEW_AT"), name];
                    section = [[[Section alloc] initWithName:name row:offset localize:NO] autorelease];
                    [sections addObject:section];
                _end
            }

            [section addToCount];
        } else if ([package ignored]) {
            if (ignored == nil) {
                ignored = [[[Section alloc] initWithName:UCLocalize("IGNORED_UPGRADES") row:offset localize:NO] autorelease];
            }
            [ignored addToCount];
        } else {
            ++upgrades_;
            [upgradable addToCount];
        }
    }
    _trace();

    CFRelease(formatter);

    if (unseens) {
        Section *last = [sections lastObject];
        size_t count = [last count];
        [packages removeObjectsInRange:NSMakeRange([packages count] - count, count)];
        [sections removeLastObject];
    }

    if ([ignored count] != 0)
        [sections insertObject:ignored atIndex:0];
    if (upgrades_ != 0)
        [sections insertObject:upgradable atIndex:0];

    [list_ reloadData];

    [[self navigationItem] setRightBarButtonItem:(upgrades_ == 0 ? nil : [[[UIBarButtonItem alloc]
        initWithTitle:[NSString stringWithFormat:UCLocalize("PARENTHETICAL"), UCLocalize("UPGRADE"), [NSString stringWithFormat:@"%u", upgrades_]]
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(upgradeButtonClicked)
    ] autorelease]) animated:YES];

    return sections;
}

@end
/* }}} */
/* Search Controller {{{ */
@interface SearchController : FilteredPackageListController <
    UISearchBarDelegate
> {
    _H<UISearchBar, 1> search_;
    BOOL searchloaded_;
    bool summary_;
}

- (id) initWithDatabase:(Database *)database query:(NSString *)query;
- (void) reloadData;

@end

@implementation SearchController

- (NSURL *) referrerURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/search?q=%@", UI_, [([search_ text] ?: @"") stringByAddingPercentEscapesIncludingReserved]]];
}

- (NSURL *) navigationURL {
    if ([search_ text] == nil || [[search_ text] isEqualToString:@""])
        return [NSURL URLWithString:@"cydia://search"];
    else
        return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://search/%@", [[search_ text] stringByAddingPercentEscapesIncludingReserved]]];
}

- (NSArray *) termsForQuery:(NSString *)query {
    NSMutableArray *terms([NSMutableArray arrayWithCapacity:2]);
    for (NSString *component in [query componentsSeparatedByString:@" "])
        if ([component length] != 0)
            [terms addObject:component];

    return terms;
}

- (void) useSearch {
    _H<NSArray> query([self termsForQuery:[search_ text]]);
    summary_ = false;

@synchronized (self) {
    [self setFilter:[=](Package *package) {
        if (![package unfiltered])
            return false;
        if (![package matches:query])
            return false;
        return true;
    }];

    [self setSorter:[](NSMutableArray *packages) {
        [packages radixSortUsingSelector:@selector(rank)];
    }];
}

    [self clearData];
    [self reloadData];
}

- (void) usePrefix:(NSString *)prefix {
    _H<NSString> query(prefix);
    summary_ = true;

@synchronized (self) {
    [self setFilter:[=](Package *package) {
        if ([query length] == 0)
            return false;
        if (![package unfiltered])
            return false;
        if ([[package name] compare:query options:MatchCompareOptions_ range:NSMakeRange(0, [query length])] != NSOrderedSame)
            return false;
        return true;
    }];

    [self setSorter:nullptr];
}

    [self reloadData];
}

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self clearData];
    [self usePrefix:[search_ text]];
}

- (void) searchBarButtonClicked:(UISearchBar *)searchBar {
    [search_ resignFirstResponder];
    [self useSearch];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [search_ setText:@""];
    [self searchBarButtonClicked:searchBar];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBarButtonClicked:searchBar];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    [self usePrefix:text];
}

- (bool) shouldYield {
    return YES;
}

- (bool) shouldBlock {
    return !summary_;
}

- (bool) isSummarized {
    return summary_;
}

- (bool) showsSections {
    return false;
}

- (id) initWithDatabase:(Database *)database query:(NSString *)query {
    if ((self = [super initWithDatabase:database title:UCLocalize("SEARCH")])) {
        search_ = [[[UISearchBar alloc] init] autorelease];
        [search_ setPlaceholder:UCLocalize("SEARCH_EX")];
        [search_ setDelegate:self];

        UITextField *textField;
        if ([search_ respondsToSelector:@selector(searchField)])
            textField = [search_ searchField];
        else
            textField = MSHookIvar<UITextField *>(search_, "_searchField");

        [textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [textField setEnablesReturnKeyAutomatically:NO];
        [[self navigationItem] setTitleView:textField];

        if (query != nil)
            [search_ setText:query];
        [self useSearch];
    } return self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!searchloaded_) {
        searchloaded_ = YES;
        [search_ setFrame:CGRectMake(0, 0, [[self view] bounds].size.width, 44.0f)];
        [search_ layoutSubviews];
    }

    if ([self isSummarized])
        [search_ becomeFirstResponder];
}

- (void) reloadData {
    [self resetCursor];
    [super reloadData];
}

- (void) didSelectPackage:(Package *)package {
    [search_ resignFirstResponder];
    [super didSelectPackage:package];
}

@end
/* }}} */
/* Package Settings Controller {{{ */
@interface PackageSettingsController : CyteViewController <
    UITableViewDataSource,
    UITableViewDelegate
> {
    _transient Database *database_;
    _H<NSString> name_;
    _H<Package> package_;
    _H<UITableView, 2> table_;
    _H<UISwitch> subscribedSwitch_;
    _H<UISwitch> ignoredSwitch_;
    _H<UITableViewCell> subscribedCell_;
    _H<UITableViewCell> ignoredCell_;
}

- (id) initWithDatabase:(Database *)database package:(NSString *)package;

@end

@implementation PackageSettingsController

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@/settings", (id) name_]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (package_ == nil)
        return 0;

    if ([package_ installed] == nil)
        return 1;
    else
        return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (package_ == nil)
        return 0;

    // both sections contain just one item right now.
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0)
        return UCLocalize("SHOW_ALL_CHANGES_EX");
    else
        return UCLocalize("IGNORE_UPGRADES_EX");
}

- (void) onSubscribed:(id)control {
    bool value([control isOn]);
    if (package_ == nil)
        return;
    if ([package_ setSubscribed:value])
        [delegate_ updateData];
}

- (void) _updateIgnored {
    const char *package([name_ UTF8String]);
    bool on([ignoredSwitch_ isOn]);

    FILE *dpkg(popen("/usr/libexec/cydia/cydo --set-selections", "w"));
    fwrite(package, strlen(package), 1, dpkg);

    if (on)
        fwrite(" hold\n", 6, 1, dpkg);
    else
        fwrite(" install\n", 9, 1, dpkg);

    pclose(dpkg);
}

- (void) onIgnored:(id)control {
    NSInvocation *invocation([NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(_updateIgnored)]]);
    [invocation setTarget:self];
    [invocation setSelector:@selector(_updateIgnored)];

    [delegate_ reloadDataWithInvocation:invocation];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (package_ == nil)
        return nil;

    switch ([indexPath section]) {
        case 0: return subscribedCell_;
        case 1: return ignoredCell_;

        _nodefault
    }

    return nil;
}

- (void) loadView {
    UIView *view([[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]);
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self setView:view];

    table_ = [[[UITableView alloc] initWithFrame:[[self view] bounds] style:UITableViewStyleGrouped] autorelease];
    [table_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [(UITableView *) table_ setDataSource:self];
    [table_ setDelegate:self];
    [view addSubview:table_];

    subscribedSwitch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)] autorelease];
    [subscribedSwitch_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [subscribedSwitch_ addTarget:self action:@selector(onSubscribed:) forEvents:UIControlEventValueChanged];

    ignoredSwitch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 20)] autorelease];
    [ignoredSwitch_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [ignoredSwitch_ addTarget:self action:@selector(onIgnored:) forEvents:UIControlEventValueChanged];

    subscribedCell_ = [[[UITableViewCell alloc] init] autorelease];
    [subscribedCell_ setText:UCLocalize("SHOW_ALL_CHANGES")];
    [subscribedCell_ setAccessoryView:subscribedSwitch_];
    [subscribedCell_ setSelectionStyle:UITableViewCellSelectionStyleNone];

    ignoredCell_ = [[[UITableViewCell alloc] init] autorelease];
    [ignoredCell_ setText:UCLocalize("IGNORE_UPGRADES")];
    [ignoredCell_ setAccessoryView:ignoredSwitch_];
    [ignoredCell_ setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    [[self navigationItem] setTitle:UCLocalize("SETTINGS")];
}

- (void) releaseSubviews {
    ignoredCell_ = nil;
    subscribedCell_ = nil;
    table_ = nil;
    ignoredSwitch_ = nil;
    subscribedSwitch_ = nil;

    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database package:(NSString *)package {
    if ((self = [super init]) != nil) {
        database_ = database;
        name_ = package;
    } return self;
}

- (void) reloadData {
    [super reloadData];

    package_ = [database_ packageWithName:name_];

    if (package_ != nil) {
        [subscribedSwitch_ setOn:([package_ subscribed] ? 1 : 0) animated:NO];
        [ignoredSwitch_ setOn:([package_ ignored] ? 1 : 0) animated:NO];
    } // XXX: what now, G?

    [table_ reloadData];
}

@end
/* }}} */

/* Installed Controller {{{ */
@interface InstalledController : FilteredPackageListController {
    bool sectioned_;
}

- (id) initWithDatabase:(Database *)database;
- (void) queueStatusDidChange;

@end

@implementation InstalledController

- (NSURL *) referrerURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/installed/", UI_]];
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://installed"];
}

- (void) useRecent {
    sectioned_ = false;

@synchronized (self) {
    [self setFilter:[](Package *package) {
        return ![package uninstalled] && package->role_ < 7;
    }];

    [self setSorter:[](NSMutableArray *packages) {
        [packages radixSortUsingSelector:@selector(recent)];
    }];
} }

- (void) useFilter:(UISegmentedControl *)segmented {
    NSInteger selected([segmented selectedSegmentIndex]);
    if (selected == 2)
        return [self useRecent];
    bool simple(selected == 0);
    sectioned_ = true;

@synchronized (self) {
    [self setFilter:[=](Package *package) {
        return ![package uninstalled] && package->role_ <= (simple ? 1 : 3);
    }];

    [self setSorter:nullptr];
} }

- (NSArray *) sectionsForPackages:(NSMutableArray *)packages {
    if (sectioned_)
        return [super sectionsForPackages:packages];

    CFDateFormatterRef formatter(CFDateFormatterCreate(NULL, Locale_, kCFDateFormatterLongStyle, kCFDateFormatterNoStyle));

    NSMutableArray *sections([NSMutableArray arrayWithCapacity:16]);
    Section *section(nil);
    time_t last(0);

    for (size_t offset(0), count([packages count]); offset != count; ++offset) {
        Package *package([packages objectAtIndex:offset]);

        time_t upgraded([package upgraded]);
        if (upgraded < 1168364520)
            upgraded = 0;
        else
            upgraded -= upgraded % (60 * 60 * 24);

        if (section == nil || upgraded != last) {
            last = upgraded;

            NSString *name;
            if (upgraded == 0)
                continue; // XXX: name = UCLocalize("...");
            else {
                name = (NSString *) CFDateFormatterCreateStringWithDate(NULL, formatter, (CFDateRef) [NSDate dateWithTimeIntervalSince1970:upgraded]);
                [name autorelease];
            }

            section = [[[Section alloc] initWithName:name row:offset localize:NO] autorelease];
            [sections addObject:section];
        }

        [section addToCount];
    }

    CFRelease(formatter);
    return sections;
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super initWithDatabase:database title:UCLocalize("INSTALLED")]) != nil) {
        UISegmentedControl *segmented([[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:UCLocalize("USER"), UCLocalize("EXPERT"), UCLocalize("RECENT"), nil]] autorelease]);
        [segmented setSelectedSegmentIndex:0];
        [segmented setSegmentedControlStyle:UISegmentedControlStyleBar];
        [[self navigationItem] setTitleView:segmented];

        [segmented addTarget:self action:@selector(modeChanged:) forEvents:UIControlEventValueChanged];
        [self useFilter:segmented];

        [self queueStatusDidChange];
    } return self;
}

#if !AlwaysReload
- (void) queueButtonClicked {
    [delegate_ queue];
}
#endif

- (void) queueStatusDidChange {
#if !AlwaysReload
    if (Queuing_) {
        [[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("QUEUE")
            style:UIBarButtonItemStyleDone
            target:self
            action:@selector(queueButtonClicked)
        ] autorelease]];
    } else {
        [[self navigationItem] setRightBarButtonItem:nil];
    }
#endif
}

- (void) modeChanged:(UISegmentedControl *)segmented {
    [self useFilter:segmented];
    [self reloadData];
}

@end
/* }}} */

/* Source Cell {{{ */
@interface SourceCell : CyteTableViewCell <
    CyteTableViewCellDelegate,
    SourceDelegate
> {
    _H<Source, 1> source_;
    _H<NSURL> url_;
    _H<UIImage> icon_;
    _H<NSString> origin_;
    _H<NSString> label_;
    _H<UIActivityIndicatorView> indicator_;
}

- (void) setSource:(Source *)source;
- (void) setFetch:(NSNumber *)fetch;

@end

@implementation SourceCell

- (void) _setImage:(NSArray *)data {
    if ([url_ isEqual:[data objectAtIndex:0]]) {
        icon_ = [data objectAtIndex:1];
        [content_ setNeedsDisplay];
    }
}

- (void) _setSource:(NSURL *) url {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    if (NSData *data = [NSURLConnection
        sendSynchronousRequest:[NSURLRequest
            requestWithURL:url
            cachePolicy:NSURLRequestUseProtocolCachePolicy
            timeoutInterval:10
        ]

        returningResponse:NULL
        error:NULL
    ])
        if (UIImage *image = [UIImage imageWithData:data])
            [self performSelectorOnMainThread:@selector(_setImage:) withObject:[NSArray arrayWithObjects:url, image, nil] waitUntilDone:NO];

    [pool release];
}

- (void) setSource:(Source *)source {
    source_ = source;
    [source_ setDelegate:self];

    [self setFetch:[NSNumber numberWithBool:[source_ fetch]]];

    icon_ = [UIImage imageNamed:@"unknown.png"];

    origin_ = [source name];
    label_ = [source rooturi];

    [content_ setNeedsDisplay];

    url_ = [source iconURL];
    [NSThread detachNewThreadSelector:@selector(_setSource:) toTarget:self withObject:url_];
}

- (void) setAllSource {
    source_ = nil;
    [indicator_ stopAnimating];

    icon_ = [UIImage imageNamed:@"folder.png"];
    origin_ = UCLocalize("ALL_SOURCES");
    label_ = UCLocalize("ALL_SOURCES_EX");
    [content_ setNeedsDisplay];
}

- (SourceCell *) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) != nil) {
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);

        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content_ setBackgroundColor:[UIColor whiteColor]];
        [content addSubview:content_];

        [content_ setDelegate:self];
        [content_ setOpaque:YES];

        indicator_ = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGraySmall] autorelease];
        [indicator_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];// | UIViewAutoresizingFlexibleBottomMargin];
        [content addSubview:indicator_];

        [[content_ layer] setContentsGravity:kCAGravityTopLeft];
    } return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];

    UIView *content([self contentView]);
    CGRect bounds([content bounds]);

    CGRect frame([indicator_ frame]);
    frame.origin.x = bounds.size.width - frame.size.width;
    frame.origin.y = Retina((bounds.size.height - frame.size.height) / 2);

    if (kCFCoreFoundationVersionNumber < 800)
        frame.origin.x -= 8;
    [indicator_ setFrame:frame];
}

- (NSString *) accessibilityLabel {
    return origin_;
}

- (void) drawContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width(rect.size.width);

    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];

        while (rect.size.width > 32 || rect.size.height > 32) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }

        rect.origin.x = 26 - rect.size.width / 2;
        rect.origin.y = 26 - rect.size.height / 2;

        [icon_ drawInRect:Retina(rect)];
    }

    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor(White_);

    if (!highlighted)
        UISetColor(Black_);
    [origin_ drawAtPoint:CGPointMake(52, 8) forWidth:(width - 49) withFont:Font18Bold_ lineBreakMode:NSLineBreakByTruncatingTail];

    if (!highlighted)
        UISetColor(Gray_);
    [label_ drawAtPoint:CGPointMake(52, 29) forWidth:(width - 49) withFont:Font12_ lineBreakMode:NSLineBreakByTruncatingTail];
}

- (void) setFetch:(NSNumber *)fetch {
    if ([fetch boolValue])
        [indicator_ startAnimating];
    else
        [indicator_ stopAnimating];
}

@end
/* }}} */
/* Sources Controller {{{ */
@interface SourcesController : CyteViewController <
    UITableViewDataSource,
    UITableViewDelegate
> {
    _transient Database *database_;
    unsigned era_;

    _H<UITableView, 2> list_;
    _H<NSMutableArray> sources_;
    int offset_;

    _H<NSString> href_;
    _H<UIProgressHUD> hud_;
    _H<NSError> error_;

    NSURLConnection *trivial_bz2_;
    NSURLConnection *trivial_gz_;

    BOOL cydia_;
}

- (id) initWithDatabase:(Database *)database;
- (void) updateButtonsForEditingStatusAnimated:(BOOL)animated;

@end

@implementation SourcesController

- (void) _releaseConnection:(NSURLConnection *)connection {
    if (connection != nil) {
        [connection cancel];
        //[connection setDelegate:nil];
        [connection release];
    }
}

- (void) dealloc {
    [self _releaseConnection:trivial_gz_];
    [self _releaseConnection:trivial_bz2_];

    [super dealloc];
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:@"cydia://sources"];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [list_ deselectRowAtIndexPath:[list_ indexPathForSelectedRow] animated:animated];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1)
        return UCLocalize("INDIVIDUAL_SOURCES");
    return nil;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return [sources_ count];
        default: return 0;
    }
}

- (Source *) sourceAtIndexPath:(NSIndexPath *)indexPath {
@synchronized (database_) {
    if ([database_ era] != era_)
        return nil;
    if ([indexPath section] != 1)
        return nil;
    NSUInteger index([indexPath row]);
    if (index >= [sources_ count])
        return nil;
    return [sources_ objectAtIndex:index];
} }

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SourceCell";

    SourceCell *cell = (SourceCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) cell = [[[SourceCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

    Source *source([self sourceAtIndexPath:indexPath]);
    if (source == nil)
        [cell setAllSource];
    else
        [cell setSource:source];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SectionsController *controller([[[SectionsController alloc]
        initWithDatabase:database_
        source:[self sourceAtIndexPath:indexPath]
    ] autorelease]);

    [controller setDelegate:delegate_];
    [[self navigationController] pushViewController:controller animated:YES];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] != 1)
        return false;
    Source *source = [self sourceAtIndexPath:indexPath];
    return [source record] != nil;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    _assert([indexPath section] == 1);
    if (editingStyle ==  UITableViewCellEditingStyleDelete) {
        Source *source = [self sourceAtIndexPath:indexPath];
        if (source == nil) return;

        [Sources_ removeObjectForKey:[source key]];

        [delegate_ _saveConfig];
        [delegate_ reloadDataWithInvocation:nil];
    }
}

- (void) tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateButtonsForEditingStatusAnimated:YES];
}

- (void) complete {
    [delegate_ addTrivialSource:href_];
    href_ = nil;

    [delegate_ syncData];
}

- (NSString *) getWarning {
    NSString *href(href_);
    NSRange colon([href rangeOfString:@"://"]);
    if (colon.location != NSNotFound)
        href = [href substringFromIndex:(colon.location + 3)];
    href = [href stringByAddingPercentEscapes];
    href = [CydiaURL(@"api/repotag/") stringByAppendingString:href];

    NSURL *url([NSURL URLWithString:href]);

    NSStringEncoding encoding;
    NSError *error(nil);

    if (NSString *warning = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error])
        return [warning length] == 0 ? nil : warning;
    return nil;
}

- (void) _endConnection:(NSURLConnection *)connection {
    // XXX: the memory management in this method is horribly awkward

    NSURLConnection **field = NULL;
    if (connection == trivial_bz2_)
        field = &trivial_bz2_;
    else if (connection == trivial_gz_)
        field = &trivial_gz_;
    _assert(field != NULL);
    [connection release];
    *field = nil;

    if (
        trivial_bz2_ == nil &&
        trivial_gz_ == nil
    ) {
        NSString *warning(cydia_ ? [self yieldToSelector:@selector(getWarning)] : nil);

        [delegate_ releaseNetworkActivityIndicator];

        [delegate_ removeProgressHUD:hud_];
        hud_ = nil;

        if (cydia_) {
            if (warning != nil) {
                UIAlertView *alert = [[[UIAlertView alloc]
                    initWithTitle:UCLocalize("SOURCE_WARNING")
                    message:warning
                    delegate:self
                    cancelButtonTitle:UCLocalize("CANCEL")
                    otherButtonTitles:
                        UCLocalize("ADD_ANYWAY"),
                    nil
                ] autorelease];

                [alert setContext:@"warning"];
                [alert setNumberOfRows:1];
                [alert show];

                // XXX: there used to be this great mechanism called yieldToPopup... who deleted it?
                error_ = nil;
                return;
            }

            [self complete];
        } else if (error_ != nil) {
            UIAlertView *alert = [[[UIAlertView alloc]
                initWithTitle:UCLocalize("VERIFICATION_ERROR")
                message:[error_ localizedDescription]
                delegate:self
                cancelButtonTitle:UCLocalize("OK")
                otherButtonTitles:nil
            ] autorelease];

            [alert setContext:@"urlerror"];
            [alert show];

            href_ = nil;
        } else {
            UIAlertView *alert = [[[UIAlertView alloc]
                initWithTitle:UCLocalize("NOT_REPOSITORY")
                message:UCLocalize("NOT_REPOSITORY_EX")
                delegate:self
                cancelButtonTitle:UCLocalize("OK")
                otherButtonTitles:nil
            ] autorelease];

            [alert setContext:@"trivial"];
            [alert show];

            href_ = nil;
        }

        error_ = nil;
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    switch ([response statusCode]) {
        case 200:
            cydia_ = YES;
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    lprintf("connection:\"%s\" didFailWithError:\"%s\"\n", [href_ UTF8String], [[error localizedDescription] UTF8String]);
    error_ = error;
    [self _endConnection:connection];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self _endConnection:connection];
}

- (NSURLConnection *) _requestHRef:(NSString *)href method:(NSString *)method {
    NSURL *url([NSURL URLWithString:href]);

    NSMutableURLRequest *request = [NSMutableURLRequest
        requestWithURL:url
        cachePolicy:NSURLRequestUseProtocolCachePolicy
        timeoutInterval:10
    ];

    [request setHTTPMethod:method];

    if (Machine_ != NULL)
        [request setValue:[NSString stringWithUTF8String:Machine_] forHTTPHeaderField:@"X-Machine"];

    if (UniqueID_ != nil)
        [request setValue:UniqueID_ forHTTPHeaderField:@"X-Unique-ID"];

    if ([url isCydiaSecure]) {
        if (UniqueID_ != nil)
            [request setValue:UniqueID_ forHTTPHeaderField:@"X-Cydia-Id"];
    }

    return [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button {
    NSString *context([alert context]);

    if ([context isEqualToString:@"source"]) {
        switch (button) {
            case 1: {
                NSString *href = [[alert textField] text];
                href = VerifySource(href);
                if (href == nil)
                    break;
                href_ = href;

                trivial_bz2_ = [[self _requestHRef:[href_ stringByAppendingString:@"Packages.bz2"] method:@"HEAD"] retain];
                trivial_gz_ = [[self _requestHRef:[href_ stringByAppendingString:@"Packages.gz"] method:@"HEAD"] retain];

                cydia_ = false;

                // XXX: this is stupid
                hud_ = [delegate_ addProgressHUD];
                [hud_ setText:UCLocalize("VERIFYING_URL")];
                [delegate_ retainNetworkActivityIndicator];
            } break;

            case 0:
            break;

            _nodefault
        }

        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else if ([context isEqualToString:@"trivial"])
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    else if ([context isEqualToString:@"urlerror"])
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    else if ([context isEqualToString:@"warning"]) {
        switch (button) {
            case 1:
                [self performSelector:@selector(complete) withObject:nil afterDelay:0];
            break;

            case 0:
            break;

            _nodefault
        }

        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    }
}

- (void) updateButtonsForEditingStatusAnimated:(BOOL)animated {
    BOOL editing([list_ isEditing]);

    if (editing)
        [[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("ADD")
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(addButtonClicked)
        ] autorelease] animated:animated];
    else if ([delegate_ updating])
        [[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("CANCEL")
            style:UIBarButtonItemStyleDone
            target:self
            action:@selector(cancelButtonClicked)
        ] autorelease] animated:animated];
    else
        [[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc]
            initWithTitle:UCLocalize("REFRESH")
            style:UIBarButtonItemStylePlain
            target:self
            action:@selector(refreshButtonClicked)
        ] autorelease] animated:animated];

    [[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc]
        initWithTitle:(editing ? UCLocalize("DONE") : UCLocalize("EDIT"))
        style:(editing ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain)
        target:self
        action:@selector(editButtonClicked)
    ] autorelease] animated:animated];
}

- (void) loadView {
    list_ = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain] autorelease];
    [list_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [list_ setRowHeight:53];
    [(UITableView *) list_ setDataSource:self];
    [list_ setDelegate:self];
    [self setView:list_];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    [[self navigationItem] setTitle:UCLocalize("SOURCES")];
    [self updateButtonsForEditingStatusAnimated:NO];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [list_ setEditing:NO];
    [self updateButtonsForEditingStatusAnimated:NO];
}

- (void) releaseSubviews {
    list_ = nil;

    sources_ = nil;

    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;
    } return self;
}

- (void) reloadData {
    [super reloadData];
    [self updateButtonsForEditingStatusAnimated:YES];

@synchronized (database_) {
    era_ = [database_ era];

    sources_ = [NSMutableArray arrayWithCapacity:16];
    [sources_ addObjectsFromArray:[database_ sources]];
    _trace();
    [sources_ sortUsingSelector:@selector(compareByName:)];
    _trace();

    int count([sources_ count]);
    offset_ = 0;
    for (int i = 0; i != count; i++) {
        if ([[sources_ objectAtIndex:i] record] == nil)
            break;
        offset_++;
    }

    [list_ reloadData];
} }

- (void) showAddSourcePrompt {
    UIAlertView *alert = [[[UIAlertView alloc]
        initWithTitle:UCLocalize("ENTER_APT_URL")
        message:nil
        delegate:self
        cancelButtonTitle:UCLocalize("CANCEL")
        otherButtonTitles:
            UCLocalize("ADD_SOURCE"),
        nil
    ] autorelease];

    [alert setContext:@"source"];

    [alert setNumberOfRows:1];
    [alert addTextFieldWithValue:@"http://" label:@""];

    UITextInputTraits *traits = [[alert textField] textInputTraits];
    [traits setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [traits setAutocorrectionType:UITextAutocorrectionTypeNo];
    [traits setKeyboardType:UIKeyboardTypeURL];
    // XXX: UIReturnKeyDone
    [traits setReturnKeyType:UIReturnKeyNext];

    [alert show];
}

- (void) addButtonClicked {
    [self showAddSourcePrompt];
}

- (void) refreshButtonClicked {
    if ([delegate_ requestUpdate])
        [self updateButtonsForEditingStatusAnimated:YES];
}

- (void) cancelButtonClicked {
    [delegate_ cancelUpdate];
}

- (void) editButtonClicked {
    [list_ setEditing:![list_ isEditing] animated:YES];
    [self updateButtonsForEditingStatusAnimated:YES];
}

@end
/* }}} */

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
