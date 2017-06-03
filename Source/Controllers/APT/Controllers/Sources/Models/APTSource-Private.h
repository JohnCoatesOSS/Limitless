//
//  APTSource-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

#import "APTSource.h"

@interface APTSource (Private)

@property (readonly) metaIndex *metaIndex;

- (instancetype)initWithMetaIndex:(metaIndex *)metaIndex;

@end
