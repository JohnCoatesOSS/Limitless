//
//  APTPackageManager-Private.h
//  Limitless
//
//  Created on 12/19/16.
//  
//

#import "APTPackageManager.h"

@interface APTPackageManager (Private)

- (BOOL)queueArchivesForDownloadWithScheduler:(APTDownloadScheduler *)downloadScheduler
                                   sourceList:(APTSourceList *)sourceList
                               packageRecords:(APTRecords *)records;

@end
