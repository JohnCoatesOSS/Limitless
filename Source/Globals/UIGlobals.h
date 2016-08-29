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

static CYColor Blue_;
static CYColor Blueish_;
static CYColor Black_;
static CYColor Folder_;
static CYColor Off_;
static CYColor White_;
static CYColor Gray_;
static CYColor Green_;
static CYColor Purple_;
static CYColor Purplish_;

static UIColor *InstallingColor_;
static UIColor *RemovingColor_;

static CGColorSpaceRef space_;

// Fonts

static _H<UIFont> Font12_;
static _H<UIFont> Font12Bold_;
static _H<UIFont> Font14_;
static _H<UIFont> Font18_;
static _H<UIFont> Font18Bold_;
static _H<UIFont> Font22Bold_;

// Collation

static _H<NSLocale> CollationLocale_;
static _H<NSArray> CollationThumbs_;
static std::vector<NSInteger> CollationOffset_;
static _H<NSArray> CollationTitles_;
static _H<NSArray> CollationStarts_;
static UTransliterator *CollationTransl_;

typedef std::basic_string<UChar> ustring;
static ustring CollationString_;

// Locale

static CFLocaleRef Locale_;
static NSArray *Languages_;