//
//  LMXAPTSource.m
//  Limitless
//
//  Created on 12/5/16.
//

#import "APTSource.h"

@interface APTSource ()

@end

@implementation APTSource

- (instancetype)init {
    self = [super init];

    if (self) {

    }

    return self;
}

// MARK: - Debugging

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@ %@>",
            NSStringFromClass([self class]),
            self.name,
            self.origin
            ];
}

@end
