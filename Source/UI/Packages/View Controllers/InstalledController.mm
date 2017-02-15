//
//  InstalledController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "InstalledController.h"
#import "Database.h"
#import "Package.h"
#import "Flags.h"
#import "Section.h"
#import "ConfirmationController.h"

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
    }
}

static BOOL _isFiltered = NO;

+ (BOOL)isFiltered {
    return _isFiltered;
}

+ (void)setIsFiltered:(BOOL)isFiltered {
    _isFiltered = isFiltered;
}

- (void) useFilter:(UISegmentedControl *)segmented {
    NSInteger selected([segmented selectedSegmentIndex]);
    // FIXME: Favorites broken. Switching off for Beta 5
//    if (selected == 3) {
//        [self setIsFiltered:YES];
//    } else {
//        [self setIsFiltered:NO];
//    }
    if (selected == 2)
        return [self useRecent];
    bool simple(selected == 0);
    sectioned_ = true;
    
    @synchronized (self) {
        [self setFilter:[=](Package *package) {
            return ![package uninstalled] && package->role_ <= (simple ? 1 : 3);
        }];
        
        [self setSorter:nullptr];
    }
}

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
        UISegmentedControl *segmented([[[UISegmentedControl alloc] initWithItems:@[
                                                                                   UCLocalize("USER"),
                                                                                   UCLocalize("EXPERT"),
                                                                                   UCLocalize("RECENT"),
                                                                                   // FIXME: Favorites broken. Switching off for Beta 5
                                                                                   //UCLocalize("FAVORITES")
                                                                                    ]] autorelease]);
        [segmented setSelectedSegmentIndex:0];
        [[self navigationItem] setTitleView:segmented];
        
        [segmented addTarget:self action:@selector(modeChanged:) forEvents:UIControlEventValueChanged];
        [self useFilter:segmented];
        
        [self queueStatusDidChange];
    } return self;
}

#if !AlwaysReload
- (void) queueButtonClicked {
    [self.delegate queue];
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
