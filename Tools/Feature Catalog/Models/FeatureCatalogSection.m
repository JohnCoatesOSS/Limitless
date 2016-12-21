//
//  FeatureCatalogSection.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "FeatureCatalogSection.h"

@interface FeatureCatalogSection ()

@end

@implementation FeatureCatalogSection

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];

    if (self) {
        _title = title;
        _items = @[];
    }

    return self;
}

- (void)addItem:(FeatureCatalogItem *)item {
    NSMutableArray *mutableItems = self.items.mutableCopy;
    [mutableItems addObject:item];
    self.items = mutableItems;
}

@end
