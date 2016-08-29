//
//  DisplayHelpers.mm
//  Cydia
//
//  Created by John Coates on 8/29/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import "DisplayHelpers.hpp"

bool IsWildcat_;
CGFloat ScreenScale_;

CGFloat CYStatusBarHeight() {
    CGSize size([[UIApplication sharedApplication] statusBarFrame].size);
    return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? size.height : size.width;
}

NSString *LocalizeSection(NSString *section) {
    static RegEx title_r("(.*?) \\((.*)\\)");
    if (title_r(section)) {
        NSString *parent(title_r[1]);
        NSString *child(title_r[2]);
        
        return [NSString stringWithFormat:UCLocalize("PARENTHETICAL"),
                LocalizeSection(parent),
                LocalizeSection(child)
                ];
    }
    
    return [[NSBundle mainBundle] localizedStringForKey:section value:nil table:@"Sections"];
}

NSString *Simplify(NSString *title) {
    const char *data = [title UTF8String];
    size_t size = [title lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    static RegEx square_r("\\[(.*)\\]");
    if (square_r(data, size))
        return Simplify(square_r[1]);
    
    static RegEx paren_r("\\((.*)\\)");
    if (paren_r(data, size))
        return Simplify(paren_r[1]);
    
    static RegEx title_r("(.*?) \\((.*)\\)");
    if (title_r(data, size))
        return Simplify(title_r[1]);
    
    return title;
}

bool isSectionVisible(NSString *section) {
    NSDictionary *metadata([Sections_ objectForKey:(section ?: @"")]);
    NSNumber *hidden(metadata == nil ? nil : [metadata objectForKey:@"Hidden"]);
    return hidden == nil || ![hidden boolValue];
}
