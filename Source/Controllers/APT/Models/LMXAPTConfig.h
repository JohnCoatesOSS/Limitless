//
//  LMXAPTConfig.h
//  Limitless
//
//  Created on 12/6/16.
//

@interface LMXAPTConfig : NSObject

- (NSString *)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(NSString *)obj forKeyedSubscript:(NSString *)key;

@end
