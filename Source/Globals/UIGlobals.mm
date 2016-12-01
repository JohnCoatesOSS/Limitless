//
//  UIGlobals.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "UIGlobals.h"

CGColorSpaceRef space_;

// Fonts
_H<UIFont> Font12_;
_H<UIFont> Font12Bold_;
_H<UIFont> Font14_;
_H<UIFont> Font18_;
_H<UIFont> Font18Bold_;
_H<UIFont> Font22Bold_;

// Locale
CFLocaleRef Locale_;
NSArray *Languages_;

// Sections
NSDictionary *SectionMap_;
_H<NSDate> Backgrounded_;
_transient NSMutableDictionary *Values_;
_transient NSMutableDictionary *Sections_;

// Strings

NSString *Colon_;
NSString *Elision_;
NSString *Error_;
NSString *Warning_;
const NSString *UI_;
