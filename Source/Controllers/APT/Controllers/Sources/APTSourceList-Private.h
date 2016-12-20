//
//  APTSourceList-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTSourceList.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTSourceList (Private)

@property (readonly) pkgSourceList *list;

- (BOOL)updateWithStatusDelegate:(pkgAcquireStatus &)progress;

@end

APT_SILENCE_DEPRECATIONS_END
