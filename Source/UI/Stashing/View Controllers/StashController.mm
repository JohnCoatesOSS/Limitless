//
//  StashController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "StashController.h"
#import "DisplayHelpers.hpp"

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
