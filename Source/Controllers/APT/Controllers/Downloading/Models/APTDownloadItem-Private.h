//
//  APTDownloadItem-Private.h
//  Limitless
//
//  Created by John Coates on 12/20/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTDownloadItem.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTDownloadItem (Private)

- (instancetype)initWithItem:(pkgAcquire::Item *)item;

@end

APT_SILENCE_DEPRECATIONS_END
