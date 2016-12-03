//
//  SearchController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Substrate.hpp"
#import "SearchController.h"

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
        
        if(UIColor.isDarkModeEnabled) {
            [textField setBackgroundColor:[UIColor cydia_black]];
            [textField setTextColor:[UIColor whiteColor]];
            [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
        }
        
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
