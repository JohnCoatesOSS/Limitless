//
//  NSString+Paths.m
//  Limitless
//
//  Created on 12/6/16.
//

#import "NSString+Paths.h"

@implementation NSString (Paths)

- (NSString *)subpath:(NSString *)subpath {
    return [self stringByAppendingPathComponent:subpath];
}

@end
