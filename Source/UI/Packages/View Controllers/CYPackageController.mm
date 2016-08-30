//
//  CYPackageController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "CYPackageController.h"
#import "Flags.h"
#import "UIGlobals.h"
#import "DisplayHelpers.hpp"

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
