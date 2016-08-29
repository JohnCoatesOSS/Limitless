//
//  Delegates.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "iPhonePrivate.h"

@class Cydia;
@class Package;
@class Source;
@class CydiaProgressEvent;

@protocol DatabaseDelegate
- (void) repairWithSelector:(SEL)selector;
- (void) setConfigurationData:(NSString *)data;
- (void) addProgressEventOnMainThread:(CydiaProgressEvent *)event forTask:(NSString *)task;
@end

@class CYPackageController;

@protocol SourceDelegate
- (void) setFetch:(NSNumber *)fetch;
@end

@protocol FetchDelegate
- (bool) isSourceCancelled;
- (void) startSourceFetch:(NSString *)uri;
- (void) stopSourceFetch:(NSString *)uri;
@end

@protocol CydiaDelegate
- (void) returnToCydia;
- (void) saveState;
- (void) retainNetworkActivityIndicator;
- (void) releaseNetworkActivityIndicator;
- (void) clearPackage:(Package *)package;
- (void) installPackage:(Package *)package;
- (void) installPackages:(NSArray *)packages;
- (void) removePackage:(Package *)package;
- (void) beginUpdate;
- (BOOL) updating;
- (bool) requestUpdate;
- (void) distUpgrade;
- (void) loadData;
- (void) updateData;
- (void) _saveConfig;
- (void) syncData;
- (void) addSource:(NSDictionary *)source;
- (BOOL) addTrivialSource:(NSString *)href;
- (UIProgressHUD *) addProgressHUD;
- (void) removeProgressHUD:(UIProgressHUD *)hud;
- (void) showActionSheet:(UIActionSheet *)sheet fromItem:(UIBarButtonItem *)item;
- (void) reloadDataWithInvocation:(NSInvocation *)invocation;
@end