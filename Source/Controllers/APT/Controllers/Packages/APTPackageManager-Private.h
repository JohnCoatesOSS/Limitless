//
//  APTPackageManager-Private.h
//  Limitless
//
//  Created by John Coates on 12/19/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "APTPackageManager.h"

@interface APTPackageManager (Private)

- (BOOL)queueArchivesForDownloadWithScheduler:(APTDownloadScheduler *)downloadScheduler
                                   sourceList:(APTSourceList *)sourceList
                               packageRecords:(APTRecords *)records;

@end
