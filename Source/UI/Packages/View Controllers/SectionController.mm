//
//  SectionController.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "SectionController.h"
#import "DisplayHelpers.hpp"

@implementation SectionController

- (NSURL *) referrerURL {
    NSString *name(section_);
    name = name ?: @"*";
    NSString *key(key_);
    key = key ?: @"*";
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/#!/sections/%@/%@", UI_, [key stringByAddingPercentEscapesIncludingReserved], [name stringByAddingPercentEscapesIncludingReserved]]];
}

- (NSURL *) navigationURL {
    NSString *name(section_);
    name = name ?: @"*";
    NSString *key(key_);
    key = key ?: @"*";
    return [NSURL URLWithString:[NSString stringWithFormat:@"cydia://sections/%@/%@", [key stringByAddingPercentEscapesIncludingReserved], [name stringByAddingPercentEscapesIncludingReserved]]];
}

- (id) initWithDatabase:(Database *)database source:(Source *)source section:(NSString *)section {
    NSString *title;
    if (section == nil)
        title = UCLocalize("ALL_PACKAGES");
    else if (![section isEqual:@""])
        title = [[NSBundle mainBundle] localizedStringForKey:Simplify(section) value:nil table:@"Sections"];
    else
        title = UCLocalize("NO_SECTION");
    
    if ((self = [super initWithDatabase:database title:title]) != nil) {
        key_ = [source key];
        section_ = section;
    } return self;
}

- (void) reloadData {
    Source *source([database_ sourceWithKey:key_]);
    _H<NSString> name(section_);
    
    [self setFilter:[=](Package *package) {
        NSString *section([package section]);
        
        return (
                name == nil ||
                (section == nil && [name length] == 0) ||
                [name isEqualToString:section]
                ) && (
                      source == nil ||
                      [package source] == source
                      ) && [package visible];
    }];
    
    [super reloadData];
}

@end