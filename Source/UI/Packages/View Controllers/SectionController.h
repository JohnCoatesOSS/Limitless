//
//  SectionController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"
#import "FilteredPackageListController.h"

@interface SectionController : FilteredPackageListController {
    _H<NSString> key_;
    _H<NSString> section_;
}

- (id) initWithDatabase:(Database *)database source:(Source *)source section:(NSString *)section;

@end