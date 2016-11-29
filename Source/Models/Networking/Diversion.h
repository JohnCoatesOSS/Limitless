//
//  Diversion.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"

static _H<NSMutableSet> Diversions_;

@interface Diversion : NSObject {
    RegEx pattern_;
    _H<NSString> key_;
    _H<NSString> format_;
}

- (id) initWithFrom:(NSString *)from to:(NSString *)to;
+ (NSURL *) divertURL:(NSURL *)url;

@end
