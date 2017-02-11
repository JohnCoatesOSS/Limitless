//
//  ProgressController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "System.h"
#import "ProgressController.h"
#import "GeneralHelpers.h"
#import "SwipeActionController.h"


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

- (UIBarButtonItem *) rightButton {
    return [[progress_ running] boolValue] ? [super rightButton] : [[[UIBarButtonItem alloc]
                                                                     initWithTitle:UCLocalize("CLOSE")
                                                                     style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(closeWithoutAnyPostInstallActions) // TODO: decide whether or not use the original -close method
                                                                     ] autorelease];
}

- (void) applyRightButton
{
    [[self navigationItem] setRightBarButtonItem:![[progress_ running] boolValue] ? [self rightButton] : nil];
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

// The original -close method may respring or reboot device, but we don't want that - just close the progress window
- (void) closeWithoutAnyPostInstallActions
{
    UpdateExternalStatus(0);
    [delegate_ returnToCydia];
    [super close];
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

- (void) invoke:(NSInvocation *)invocation withTitle:(NSString *)title {
    UpdateExternalStatus(1);
    
    [progress_ setRunning:YES];
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
    
    [progress_ setRunning:NO];
    [self updateProgress];
    
    [self applyRightButton];
    
    // TODO: Let user specify when to auto-close installation page
    if ([[SwipeActionController sharedInstance] dismissAfterProgress] && Finish_ != 1 && Finish_ != 4) {
        [[SwipeActionController sharedInstance] setDismissAfterProgress:NO];
        [self closeWithoutAnyPostInstallActions];
    }
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

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
