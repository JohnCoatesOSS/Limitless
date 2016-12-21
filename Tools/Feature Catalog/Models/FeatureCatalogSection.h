//
//  FeatureCatalogSection.h
//  Limitless
//
//  Created on 12/20/16.
//

@class FeatureCatalogItem;

@interface FeatureCatalogSection : NSObject

@property (readonly) NSString *title;
@property (strong) NSArray<FeatureCatalogItem *> *items;

- (instancetype)initWithTitle:(NSString *)title;

- (void)addItem:(FeatureCatalogItem *)item;

@end
