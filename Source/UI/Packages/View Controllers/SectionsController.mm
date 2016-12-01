//
//  SectionsController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "SectionsController.h"

#import "Database.h"
#import "Source.h"
#import "Section.h"
#import "SectionCell.h"
#import "SectionController.h"
#import "DisplayHelpers.hpp"
#import "NSString+Cydia.hpp"

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
    if (cell == nil) {
        cell = [[[SectionCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];
    }
	
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
