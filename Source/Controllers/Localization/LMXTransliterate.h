//
//  LMXTransliterate.h
//  Limitless
//
//  Created by John Coates on 11/29/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMXTransliterate : NSObject

+ (BOOL)transliterate:(CYString)name
                 pool:(CYPool *)pool
               output:(CYString *)output;

@end
