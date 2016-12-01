//
//  SourcesController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "SourcesController.h"
#import "Database.h"
#import "iPhonePrivate.h"
#import "Delegates.h"
#import "SourceCell.h"
#import "SectionsController.h"
#import "SystemGlobals.h"
#import "SystemHelpers.h"
#import "Networking.h"
#import "DisplayHelpers.hpp"
#import "Defines.h"
#import "Source.h"
#import "CydiaTabBarController.h"

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
	
	if (currentRepoURL && ![currentRepoURL isEqualToString:@""]) {
		[self selectSourceWithURL:currentRepoURL];
		currentRepoURL = @"";
	}
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
    if (cell == nil) {
         cell = [[[SourceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    Source *source([self sourceAtIndexPath:indexPath]);
    if (source == nil)
        [cell setAllSource];
	else {
        [cell setSource:source];
		UILongPressGestureRecognizer *favouriteGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(favouriteGestureRecognized:)];
		[cell addGestureRecognizer:favouriteGesture];
	}
	
    return cell;
}

-(void)favouriteGestureRecognized:(UILongPressGestureRecognizer*)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		Source *currentSource([self sourceAtIndexPath:[list_ indexPathForCell:(UITableViewCell*)gestureRecognizer.view]]);
		
		UIAlertController *favouriteSheet([UIAlertController alertControllerWithTitle:@"Set as favourite" message:[NSString stringWithFormat:@"Choose which favourite to replace with \"%@\"", currentSource.name] preferredStyle:UIAlertControllerStyleActionSheet]);
		
		UIApplicationShortcutItem *firstShortcut([UIApplication sharedApplication].shortcutItems[0]);
		UIApplicationShortcutItem *secondShortcut([UIApplication sharedApplication].shortcutItems[1]);
		
		UIAlertAction *firstPlaceAction([UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Slot 1 \"%@\"", firstShortcut.localizedTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction*action){
			UIMutableApplicationShortcutItem* newShortcut = [[UIMutableApplicationShortcutItem alloc] initWithType:@"repo1" localizedTitle:currentSource.name localizedSubtitle:nil icon:nil userInfo:@{@"repoURL": currentSource.rooturi}];
			NSMutableArray *newShortcuts = [NSMutableArray arrayWithArray:[UIApplication sharedApplication].shortcutItems];
			newShortcuts[0] = newShortcut;
			[UIApplication sharedApplication].shortcutItems = newShortcuts;
		}]);
		
		UIAlertAction *secondPlaceAction([UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Slot 2 \"%@\"", secondShortcut.localizedTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction*action){
			UIMutableApplicationShortcutItem* newShortcut = [[UIMutableApplicationShortcutItem alloc] initWithType:@"repo2" localizedTitle:currentSource.name localizedSubtitle:nil icon:nil userInfo:@{@"repoURL": currentSource.rooturi}];
			NSMutableArray *newShortcuts = [NSMutableArray arrayWithArray:[UIApplication sharedApplication].shortcutItems];
			newShortcuts[1] = newShortcut;
			[UIApplication sharedApplication].shortcutItems = newShortcuts;

		}]);
		UIAlertAction *cancelAction([UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil]);
		
		[favouriteSheet addAction:firstPlaceAction];
		[favouriteSheet addAction:secondPlaceAction];
		[favouriteSheet addAction:cancelAction];
		
		[self presentViewController:favouriteSheet animated:true completion:nil];
	}
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
    list_ = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]
                                          style:UITableViewStylePlain] autorelease];
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

#pragma mark - 3D Touch

- (void) selectSourceWithURL:(NSString*)sourceURL {
	
	// If sources is nil, then it hasn't fully loaded yet. We'll call this function again on viewDidAppear
	if (!sources_.operator->()) {
		currentRepoURL = sourceURL;
		return;
	}
	
	// Otherwise, we'll find the source we want and select it
	NSLog(@"Selecting source: %@", sourceURL);
	
	for (int i = 0; i < [sources_ count]; i++) {
		Source *currentSource = [sources_ objectAtIndex:i];
		if ([[currentSource rooturi] isEqualToString:sourceURL]) {
			[list_ selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1] animated:false scrollPosition:UITableViewScrollPositionNone];
			[[list_ delegate] tableView:list_ didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
			return;
		}
	}
	
	// If the source is not found, or a bug happens, the program will reach this line
	NSLog(@"Source \"%@\" not found in the list of sources", sourceURL);
	
}

@end
