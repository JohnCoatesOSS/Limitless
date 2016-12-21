//
//  FeatureCatalogItem.m
//  Limitless
//
//  Created on 12/20/16.
//

#import "FeatureCatalogItem.h"

@interface FeatureCatalogItem ()

@end

@implementation FeatureCatalogItem

- (instancetype)initWithName:(NSString *)name
               creationBlock:(CreationBlock)creationBlock {
    self = [super init];

    if (self) {
        _name = name;
        _creationBlock = creationBlock;
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [self initWithName:name creationBlock:nil];
    return self;
}

@end
