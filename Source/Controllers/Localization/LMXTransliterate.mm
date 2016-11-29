//
//  LMXTransliterate.m
//  Limitless
//
//  Created by John Coates on 11/29/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "Package.h"
#import "CydiaRelation.h"
#import "DisplayHelpers.hpp"
#import "Source.h"
#import "Standard.h"
#include <fstream>
#import "LMXTransliterate.h"

@implementation LMXTransliterate

+ (BOOL)transliterate:(CYString)name
                 pool:(CYPool *)pool
               output:(CYString *)output {
    if (CollationTransl_ == NULL) {
//        NSLog(@"Can't transliterate: No collation");
        return FALSE;
    }
    
    if (name.empty()) {
        NSLog(@"Can't transliterate: empty name");
        return FALSE;
    }
    
    // check for ascii range
//    const uint8_t *data(reinterpret_cast<const uint8_t *>(name.data()));
//    for (size_t i(0), e(name.size()); i != e; ++i) {
//        if (data[i] >= 0x80)
//            goto extended;
//    }
//    NSLog(@"Transliterate error: Nothing outside of basic ASCII range");
//    return FALSE;
    
    extended:
    
    UErrorCode code(U_ZERO_ERROR);
    int32_t length;
    
    CollationString_.resize(name.size());
    u_strFromUTF8WithSub(&CollationString_[0],
                         CollationString_.size(),
                         &length,
                         name.data(),
                         name.size(),
                         0xfffd,
                         NULL,
                         &code);
    if (!U_SUCCESS(code)) {
        NSLog(@"Transliterate error: Conversion to UTF-16 failed: %d", code);
        return FALSE;
    }
    CollationString_.resize(length);
    
    length = CollationString_.size();
    utrans_trans(CollationTransl_,
                 reinterpret_cast<UReplaceable *>(&CollationString_),
                 &CollationUCalls_,
                 0,
                 &length,
                 &code);
    if (!U_SUCCESS(code)) {
        NSLog(@"Transliteration error: %d", code);
        return FALSE;
    }
    _assert(CollationString_.size() == length);
    
    u_strToUTF8WithSub(NULL, 0, &length, CollationString_.data(), CollationString_.size(), 0xfffd, NULL, &code);
    if (code == U_BUFFER_OVERFLOW_ERROR) {
        code = U_ZERO_ERROR;
    }
    else if (!U_SUCCESS(code)) {
        NSLog(@"Transliterate error: Conversion to UTF-8 failed: %d", code);
        return FALSE;
    }
    
    char *transform;
    transform = pool->malloc<char>(length);
    u_strToUTF8WithSub(transform,
                       length,
                       NULL,
                       CollationString_.data(),
                       CollationString_.size(),
                       0xfffd,
                       NULL,
                       &code);
    
    if (!U_SUCCESS(code)) {
        NSLog(@"Transliterate error: Conversion (2) to UTF-8 failed: %d", code);
        return FALSE;
    }
    
    output->set(NULL, transform, length);
    return TRUE;
}

@end
