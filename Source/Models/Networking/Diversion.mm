//
//  Diversion.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Diversion.h"
#import "Flags.h"

@implementation Diversion

- (id) initWithFrom:(NSString *)from to:(NSString *)to {
    if ((self = [super init]) != nil) {
        pattern_ = [from UTF8String];
        key_ = from;
        format_ = to;
    } return self;
}

- (NSString *) divert:(NSString *)url {
    return !pattern_(url) ? nil : pattern_->*format_;
}

+ (NSURL *) divertURL:(NSURL *)url {
divert:
    NSString *href([url absoluteString]);
    
    for (Diversion *diversion in (id) Diversions_)
        if (NSString *diverted = [diversion divert:href]) {
#if !ForRelease
            NSLog(@"div: %@", diverted);
#endif
            url = [NSURL URLWithString:diverted];
            goto divert;
        }
    
    return url;
}

- (NSString *) key {
    return key_;
}

- (NSUInteger) hash {
    return [key_ hash];
}

- (BOOL) isEqual:(Diversion *)object {
    return self == object || ([self class] == [object class] && [key_ isEqual:[object key]]);
}

@end