//
//  APTSourceList-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

#import "APTSourceList.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTSourceList (Private)

@property (readonly) pkgSourceList *list;

- (BOOL)updateWithStatusDelegate:(pkgAcquireStatus &)progress;

@end

APT_SILENCE_DEPRECATIONS_END
