//
//  CYPackageController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Package.h"
#import "Database.h"
#import "Standard.h"
#import "CydiaWebViewController.h"

@interface CYPackageController : CydiaWebViewController <UIActionSheetDelegate> {
    _transient Database *database_;
    _H<Package> package_;
    _H<NSString> name_;
    bool commercial_;
    std::vector<std::pair<_H<NSString>, _H<NSString>>> buttons_;
    _H<UIActionSheet> sheet_;
    _H<UIBarButtonItem> button_;
    _H<NSArray> versions_;
}

- (id) initWithDatabase:(Database *)database
             forPackage:(NSString *)name
           withReferrer:(NSString *)referrer;

@end
