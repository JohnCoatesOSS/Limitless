//
//  UIGlobals.h
//  Cydia
//
//  Created on 8/29/16.
//
#import "Standard.h"
#import "Unicode.h"
#import "UIColor+CydiaColors.h"
#import "Menes/Menes.h"

extern CGColorSpaceRef space_;

// Fonts
extern _H<UIFont> Font12_;
extern _H<UIFont> Font12Bold_;
extern _H<UIFont> Font14_;
extern _H<UIFont> Font18_;
extern _H<UIFont> Font18Bold_;
extern _H<UIFont> Font22Bold_;

// Locale
extern CFLocaleRef Locale_;
extern NSArray *Languages_;

// Sections
extern NSDictionary *SectionMap_;
extern _H<NSDate> Backgrounded_;
extern _transient NSMutableDictionary *Values_;
extern _transient NSMutableDictionary *Sections_;

// Strings

extern NSString *Colon_;
extern NSString *Elision_;
extern NSString *Error_;
extern NSString *Warning_;
extern const NSString *UI_;
