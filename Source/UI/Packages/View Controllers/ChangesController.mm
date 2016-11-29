//
//  ChangesController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "ChangesController.h"
#import "Database.h"
#import "Package.h"
#import "Section.h"
#import "CydiaTabBarController.h"

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