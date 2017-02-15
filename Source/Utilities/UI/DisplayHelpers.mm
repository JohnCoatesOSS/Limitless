//
//  DisplayHelpers.mm
//  Cydia
//
//   8/29/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import "DisplayHelpers.hpp"


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

// Web
NSUInteger DOMNodeList$countByEnumeratingWithState$objects$count$(DOMNodeList *self, SEL sel, NSFastEnumerationState *state, id *objects, NSUInteger count) {
    size_t length([self length] - state->state);
    if (length <= 0)
        return 0;
    else if (length > count)
        length = count;
        for (size_t i(0); i != length; ++i)
            objects[i] = [self item:(unsigned int)state->state++];
            state->itemsPtr = objects;
            state->mutationsPtr = (unsigned long *) self;
            return length;
}
