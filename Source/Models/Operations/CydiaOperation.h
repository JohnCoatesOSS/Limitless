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

- (id) initWithOperator:(const char *)_operator value:(const char *)value;

- (NSString *) operator;
- (NSString *) value;

@end
