//
//  CydiaOperation.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
@interface CydiaOperation : NSObject {
    _H<NSString> operator_;
    _H<NSString> value_;
}

- (NSString *) operator;
- (NSString *) value;

@end
