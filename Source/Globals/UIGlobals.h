//
//  UIGlobals.h
//  Cydia
//
//  Created on 8/29/16.
//
#import "Standard.h"
#import "Unicode.h"
#import "CYColor.hpp"
#import "Menes/Menes.h"

// Colors
extern CYColor Blue_;
extern CYColor Blueish_;
extern CYColor Black_;
extern CYColor Folder_;
extern CYColor Off_;
extern CYColor White_;
extern CYColor Gray_;
extern CYColor Green_;
extern CYColor Purple_;
extern CYColor Purplish_;

extern UIColor *InstallingColor_;
extern UIColor *RemovingColor_;

extern CGColorSpaceRef space_;

// Fonts
extern _H<UIFont> Font12_;
extern _H<UIFont> Font12Bold_;
extern _H<UIFont> Font14_;
extern _H<UIFont> Font18_;
extern _H<UIFont> Font18Bold_;
extern _H<UIFont> Font22Bold_;

// Collation
typedef std::basic_string<UChar> ustring;

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
