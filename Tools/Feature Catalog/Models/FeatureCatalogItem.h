//
//  FeatureCatalogItem.h
//  Limitless
//
//  Created on 12/20/16.
//

typedef UIViewController *(^CreationBlock)();

@interface FeatureCatalogItem : NSObject

@property (readonly) NSString *name;
@property (copy) CreationBlock creationBlock;

- (instancetype)initWithName:(NSString *)name
               creationBlock:(CreationBlock)creationBlock;
- (instancetype)initWithName:(NSString *)name;

@end
