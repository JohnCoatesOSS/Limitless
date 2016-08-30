//
//  Section.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Section.h"
#import "NSString+Cydia.hpp"
#import "DisplayHelpers.hpp"

@implementation Section

- (NSComparisonResult) compareByLocalized:(Section *)section {
    NSString *lhs(localized_);
    NSString *rhs([section localized]);
    
    /*if ([lhs length] != 0 && [rhs length] != 0) {
     unichar lhc = [lhs characterAtIndex:0];
     unichar rhc = [rhs characterAtIndex:0];
     
     if (isalpha(lhc) && !isalpha(rhc))
     return NSOrderedAscending;
     else if (!isalpha(lhc) && isalpha(rhc))
     return NSOrderedDescending;
     }*/
    
    return [lhs compare:rhs options:LaxCompareOptions_];
}

- (Section *) initWithName:(NSString *)name localized:(NSString *)localized {
    if ((self = [self initWithName:name localize:NO]) != nil) {
        if (localized != nil)
            localized_ = localized;
    } return self;
}

- (Section *) initWithName:(NSString *)name localize:(BOOL)localize {
    return [self initWithName:name row:0 localize:localize];
}

- (Section *) initWithName:(NSString *)name row:(size_t)row localize:(BOOL)localize {
    if ((self = [super init]) != nil) {
        name_ = name;
        row_ = row;
        if (localize)
            localized_ = LocalizeSection(name_);
    } return self;
}

- (NSString *) name {
    return name_;
}

- (void) setName:(NSString *)name {
    name_ = name;
}

- (size_t) row {
    return row_;
}

- (size_t) count {
    return count_;
}

- (void) addToRow {
    ++row_;
}

- (void) addToCount {
    ++count_;
}

- (void) setCount:(size_t)count {
    count_ = count;
}

- (NSString *) localized {
    return localized_;
}

@end
