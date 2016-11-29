//
//  StashController.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"

@interface StashController : CyteViewController {
    _H<UIActivityIndicatorView> spinner_;
    _H<UILabel> status_;
    _H<UILabel> caption_;
}

@end