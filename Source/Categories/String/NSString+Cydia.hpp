//
//  NSString+Cydia.h
//  Cydia
//
//  Created on 8/29/16.
//

#include <algorithm>
#include <functional>
#include <iostream>
#include <vector>
#import "CyteKit.h"

@interface NSString (Cydia)
- (NSComparisonResult) compareByPath:(NSString *)other;
- (NSString *) stringByAddingPercentEscapesIncludingReserved;
@end

// C++ NSString Algorithm Adapters

extern "C" {
    CF_EXPORT CFHashCode CFStringHashNSString(CFStringRef str);
}

struct NSStringMapHash :
std::unary_function<NSString *, size_t>
{
    _finline size_t operator ()(NSString *value) const {
        return CFStringHashNSString((CFStringRef) value);
    }
};

struct NSStringMapLess :
std::binary_function<NSString *, NSString *, bool>
{
    _finline bool operator ()(NSString *lhs, NSString *rhs) const {
        return [lhs compare:rhs] == NSOrderedAscending;
    }
};

struct NSStringMapEqual :
std::binary_function<NSString *, NSString *, bool>
{
    _finline bool operator ()(NSString *lhs, NSString *rhs) const {
        return CFStringCompare((CFStringRef) lhs, (CFStringRef) rhs, 0) == kCFCompareEqualTo;
        //CFEqual((CFTypeRef) lhs, (CFTypeRef) rhs);
        //[lhs isEqualToString:rhs];
    }
};