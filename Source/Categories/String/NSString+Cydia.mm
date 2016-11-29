//
//  NSString+Cydia.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "NSString+Cydia.hpp"

@implementation NSString (Cydia)

- (NSComparisonResult) compareByPath:(NSString *)other {
    NSString *prefix = [self commonPrefixWithString:other options:0];
    size_t length = [prefix length];
    
    NSRange lrange = NSMakeRange(length, [self length] - length);
    NSRange rrange = NSMakeRange(length, [other length] - length);
    
    lrange = [self rangeOfString:@"/" options:0 range:lrange];
    rrange = [other rangeOfString:@"/" options:0 range:rrange];
    
    NSComparisonResult value;
    
    if (lrange.location == NSNotFound && rrange.location == NSNotFound)
        value = NSOrderedSame;
    else if (lrange.location == NSNotFound)
        value = NSOrderedAscending;
    else if (rrange.location == NSNotFound)
        value = NSOrderedDescending;
    else
        value = NSOrderedSame;
    
    NSString *lpath = lrange.location == NSNotFound ? [self substringFromIndex:length] :
    [self substringWithRange:NSMakeRange(length, lrange.location - length)];
    NSString *rpath = rrange.location == NSNotFound ? [other substringFromIndex:length] :
    [other substringWithRange:NSMakeRange(length, rrange.location - length)];
    
    NSComparisonResult result = [lpath compare:rpath];
    return result == NSOrderedSame ? value : result;
}

- (NSString *) stringByAddingPercentEscapesIncludingReserved {
    return [(id)CFURLCreateStringByAddingPercentEscapes(
                                                        kCFAllocatorDefault,
                                                        (CFStringRef) self,
                                                        NULL,
                                                        CFSTR(";/?:@&=+$,"),
                                                        kCFStringEncodingUTF8
                                                        ) autorelease];
}

@end