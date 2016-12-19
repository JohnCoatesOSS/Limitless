//
//  ConfirmationController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "ConfirmationController.h"
#import "Flags.h"
#import "Apt.h"
#import "Package.h"
#import "CydiaScript.h"
#import "APTCacheFile-Private.h"

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
        [self dismissViewControllerAnimated:YES completion:nil];
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    } else {
        [super alertView:alert clickedButtonAtIndex:button];
    }
}

- (void) _doContinue {
    [delegate_ cancelAndClear:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        APTCacheFile *cacheFile = database.cacheFile;
        pkgCacheFile &cache = *cacheFile.cacheFile;
//        pkgCacheFile &cache([database_ cache]);
        NSArray *packages([database_ packages]);
        APTDependencyCachePolicy *policy = database.policy;
        
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
            
            substrate_ |= [policy packageDependsOnMobileSubstrate:iterator];
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
        
        sizes_ = @{
                  @"downloading": @(database_.downloadScheduler.bytesDownloading),
                  @"resuming": @(database_.downloadScheduler.bytesDownloaded)
                  };
        
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
