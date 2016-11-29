//
//  Section.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"

@interface Section : NSObject {
    _H<NSString> name_;
    size_t row_;
    size_t count_;
    _H<NSString> localized_;
}

- (NSComparisonResult) compareByLocalized:(Section *)section;
- (Section *) initWithName:(NSString *)name localized:(NSString *)localized;
- (Section *) initWithName:(NSString *)name localize:(BOOL)localize;
- (Section *) initWithName:(NSString *)name row:(size_t)row localize:(BOOL)localize;

- (NSString *) name;
- (void) setName:(NSString *)name;

- (size_t) row;
- (size_t) count;

- (void) addToRow;
- (void) addToCount;

- (void) setCount:(size_t)count;
- (NSString *) localized;

@end