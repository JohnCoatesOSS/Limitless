//
//  FileTable.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "FileTable.h"
#import "DisplayHelpers.hpp"

@implementation FileTable

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return files_ == nil ? 0 : [files_ count];
}

/*- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
 return 24.0f;
 }*/

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
        [[cell textLabel] setFont:[UIFont systemFontOfSize:16]];
    }
    [[cell textLabel] setText:[files_ objectAtIndex:indexPath.row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (NSURL *) navigationURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@/files", [package_ id]]];
}

- (void) loadView {
    list_ = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
    [list_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
    [list_ setRowHeight:24.0f];
    [(UITableView *) list_ setDataSource:self];
    [list_ setDelegate:self];
    [self setView:list_];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem] setTitle:UCLocalize("INSTALLED_FILES")];
}

- (void) releaseSubviews {
    list_ = nil;
    
    package_ = nil;
    files_ = nil;
    
    [super releaseSubviews];
}

- (id) initWithDatabase:(Database *)database {
    if ((self = [super init]) != nil) {
        database_ = database;
    } return self;
}

- (void) setPackage:(Package *)package {
    package_ = nil;
    name_ = nil;
    
    files_ = [NSMutableArray arrayWithCapacity:32];
    
    if (package != nil) {
        package_ = package;
        name_ = [package id];
        
        if (NSArray *files = [package files])
            [files_ addObjectsFromArray:files];
        
        if ([files_ count] != 0) {
            if ([[files_ objectAtIndex:0] isEqualToString:@"/."])
                [files_ removeObjectAtIndex:0];
            [files_ sortUsingSelector:@selector(compareByPath:)];
            
            NSMutableArray *stack = [NSMutableArray arrayWithCapacity:8];
            [stack addObject:@"/"];
            
            for (int i(0), e([files_ count]); i != e; ++i) {
                NSString *file = [files_ objectAtIndex:i];
                while (![file hasPrefix:[stack lastObject]])
                    [stack removeLastObject];
                NSString *directory = [stack lastObject];
                [stack addObject:[file stringByAppendingString:@"/"]];
                [files_ replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%*s%@",
                                                           int(([stack count] - 2) * 3), "",
                                                           [file substringFromIndex:[directory length]]
                                                           ]];
            }
        }
    }
    
    [list_ reloadData];
}

- (void) reloadData {
    [super reloadData];
    
    [self setPackage:[database_ packageWithName:name_]];
}

@end
