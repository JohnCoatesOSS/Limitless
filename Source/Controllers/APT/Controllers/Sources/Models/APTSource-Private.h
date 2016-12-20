//
//  APTSource-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTSource.h"

@interface APTSource (Private)

@property (readonly) metaIndex *metaIndex;

- (instancetype)initWithMetaIndex:(metaIndex *)metaIndex;

@end
