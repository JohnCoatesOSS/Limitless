//
//  LMXLocalizedTableSections.m
//  Limitless
//
//

#import "Substrate.hpp"
#import "Package.h"
#import "CydiaRelation.h"
#import "DisplayHelpers.hpp"
#import "Source.h"
#import "Standard.h"
#import <fstream>
#import "System.h"
#import "LMXLocalizedTableSections.h"
#import <unicode/utrans.h>
#import <unicode/ustring.h>
#import "UIGlobals.h"

typedef std::basic_string<UChar> ustring;

// Collation

#define CUC const ustring &str(*reinterpret_cast<const ustring *>(rep))
#define UC ustring &str(*reinterpret_cast<ustring *>(rep))
static struct UReplaceableCallbacks CollationUCalls_ = {
    .length = [](const UReplaceable *rep) -> int32_t { CUC;
        return (int32_t)str.size();
    },
    
    .charAt = [](const UReplaceable *rep, int32_t offset) -> UChar { CUC;
        //fprintf(stderr, "charAt(%d) : %d\n", offset, str.size());
        if (offset >= str.size())
            return 0xffff;
        return str[offset];
    },
    
    .char32At = [](const UReplaceable *rep, int32_t offset) -> UChar32 { CUC;
        //fprintf(stderr, "char32At(%d) : %d\n", offset, str.size());
        if (offset >= str.size())
            return 0xffff;
        UChar32 c;
        U16_GET(str.data(), 0, offset, str.size(), c);
        return c;
    },
    
    .replace = [](UReplaceable *rep, int32_t start, int32_t limit, const UChar *text, int32_t length) -> void { UC;
        //fprintf(stderr, "replace(%d, %d, %d) : %d\n", start, limit, length, str.size());
        str.replace(start, limit - start, text, length);
    },
    
    .extract = [](UReplaceable *rep, int32_t start, int32_t limit, UChar *dst) -> void { UC;
        //fprintf(stderr, "extract(%d, %d) : %d\n", start, limit, str.size());
        str.copy(dst, limit - start, start);
    },
    
    .copy = [](UReplaceable *rep, int32_t start, int32_t limit, int32_t dest) -> void { UC;
        //fprintf(stderr, "copy(%d, %d, %d) : %d\n", start, limit, dest, str.size());
        str.replace(dest, 0, str, start, limit - start);
    },
};

@interface LMXLocalizedTableSections ()

@property (class, retain) NSLocale *collationLocale;
@property (class, retain) NSArray *collationTableIndexTitles;
@property (class, retain) NSArray *sectionTitles;
@property (class, retain) NSArray *sectionStartStrings;
@property (class, retain) NSArray <NSNumber *> *sectionsForIndexTitles;
@property (class, readwrite) UTransliterator *transliterator;

@end

@implementation LMXLocalizedTableSections

+ (void)initialize {
    [self setUpIndexCollation];
}

// MARK: - Legacy


+ (void)setUpIndexCollation {
    NSMutableArray *sectionsForIndexTitles = [[NSMutableArray new] autorelease];
    
    if (Class $UILocalizedIndexedCollation = objc_getClass("UILocalizedIndexedCollation")) { @try {
        NSBundle *bundle = [NSBundle bundleForClass:$UILocalizedIndexedCollation];
        NSString *path = [bundle pathForResource:@"UITableViewLocalizedSectionIndex" ofType:@"plist"];
        NSDictionary *dictionary([NSDictionary dictionaryWithContentsOfFile:path]);
        UILocalizedIndexedCollation *collation = [[[$UILocalizedIndexedCollation alloc] initWithDictionary:dictionary] autorelease];
        
        NSLocale *locale = MSHookIvar<NSLocale *>(collation, "_locale");
        self.collationLocale = locale;
        
        if (self.testModeEnabled) {
            NSLog(@"locale identifier: %@", [locale localeIdentifier]);
        }
        if (kCFCoreFoundationVersionNumber >= 800 && [[locale localeIdentifier] isEqualToString:@"zh@collation=stroke"]) {
            self.collationTableIndexTitles = [NSArray arrayWithObjects:@"1",@"•",@"4",@"•",@"7",@"•",@"10",@"•",@"13",@"•",@"16",@"•",@"19",@"A",@"•",@"E",@"•",@"I",@"•",@"M",@"•",@"R",@"•",@"V",@"•",@"Z",@"#",nil];
            NSInteger sectionOffsets[] = {
                0,1,3,4,6,7,9,10,12,13,15,16,
                18,25,26,29,30,33,34,37,38,42
                ,43,46,47,50,51
            };
            
            for (NSInteger section : sectionOffsets) {
                [sectionsForIndexTitles addObject:@(section)];
            }
            self.sectionsForIndexTitles = sectionsForIndexTitles;
            

            self.sectionTitles = [NSArray arrayWithObjects:@"1 畫",@"2 畫",@"3 畫",@"4 畫",@"5 畫",@"6 畫",@"7 畫",@"8 畫",@"9 畫",@"10 畫",@"11 畫",@"12 畫",@"13 畫",@"14 畫",@"15 畫",@"16 畫",@"17 畫",@"18 畫",@"19 畫",@"20 畫",@"21 畫",@"22 畫",@"23 畫",@"24 畫",@"25 畫以上",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
            self.sectionStartStrings = [NSArray arrayWithObjects:@"一",@"丁",@"丈",@"不",@"且",@"丞",@"串",@"並",@"亭",@"乘",@"乾",@"傀",@"亂",@"僎",@"僵",@"儐",@"償",@"叢",@"儳",@"嚴",@"儷",@"儻",@"囌",@"囑",@"廳",@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
        } else {
            
            NSArray *sectionIndexTitles = [collation sectionIndexTitles];
            self.collationTableIndexTitles = sectionIndexTitles;
            for (size_t index = 0, end = [sectionIndexTitles count]; index != end; ++index) {
                NSInteger section = [collation sectionForSectionIndexTitleAtIndex:index];
                [sectionsForIndexTitles addObject:@(section)];
            }
            
            self.sectionsForIndexTitles = sectionsForIndexTitles;
            
            self.sectionTitles = [collation sectionTitles];
            self.sectionStartStrings = MSHookIvar<NSArray *>(collation, "_sectionStartStrings");
            
            NSString *transform = MSHookIvar<NSString *>(collation, "_transform");
            if (transform != nil) {
                /*if ([collation respondsToSelector:@selector(transformedCollationStringForString:)])
                 CollationModify_ = [=](NSString *value) { return [collation transformedCollationStringForString:value]; };*/
                const UChar *uid(reinterpret_cast<const UChar *>([transform cStringUsingEncoding:NSUnicodeStringEncoding]));
                UErrorCode code(U_ZERO_ERROR);
                self.transliterator = utrans_openU(uid, -1, UTRANS_FORWARD, NULL, 0, NULL, &code);
                if (!U_SUCCESS(code))
                    NSLog(@"%s", u_errorName(code));
            }
            
        }
    } @catch (NSException *exception) {
        NSLog(@"[%@ %@] %@", NSStringFromClass(self), NSStringFromSelector(_cmd), exception);
        goto hard;
    } } else hard: {
        self.collationLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en@collation=dictionary"] autorelease];
        
        self.collationTableIndexTitles = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        for (NSInteger section = 0; section != 28; ++section) {
            [sectionsForIndexTitles addObject:@(section)];
        }
        self.sectionsForIndexTitles = sectionsForIndexTitles;
        
        
        self.sectionTitles = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        self.sectionStartStrings = [NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
    }
}

+ (BOOL)transliterate:(CYString)name
                 pool:(CYPool *)pool
               output:(CYString *)output {
    UTransliterator *transliterator = self.transliterator;
    if (transliterator == NULL) {
//        NSLog(@"Can't transliterate: No collation");
        return FALSE;
    }
    
    if (name.empty()) {
        NSLog(@"Can't transliterate: empty name");
        return FALSE;
    }
    
    if (!self.testModeEnabled) {
        // check for ascii range
        
        const uint8_t *data(reinterpret_cast<const uint8_t *>(name.data()));
        for (size_t i(0), e(name.size()); i != e; ++i) {
            if (data[i] >= 0x80)
                goto extended;
        }
        NSLog(@"Transliterate error: Nothing outside of basic ASCII range");
        return FALSE;
    }
    
    extended:
    
    static ustring CollationString_;
    UErrorCode code(U_ZERO_ERROR);
    int32_t length;
    CollationString_.resize(name.size());
    u_strFromUTF8WithSub(&CollationString_[0],
                         (int32_t)CollationString_.size(),
                         &length,
                         name.data(),
                         (int32_t)name.size(),
                         0xfffd,
                         NULL,
                         &code);
    if (!U_SUCCESS(code)) {
        NSLog(@"Transliterate error: Conversion to UTF-16 failed: %d", code);
        return FALSE;
    }
    CollationString_.resize(length);
    
    length = (int32_t)CollationString_.size();
    utrans_trans(transliterator,
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
    
    u_strToUTF8WithSub(NULL, 0, &length, CollationString_.data(), (int32_t)CollationString_.size(), 0xfffd, NULL, &code);
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
                       (int32_t)CollationString_.size(),
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


// MARK: - Class Properties

static int _testModeEnabled = false;
+ (BOOL)testModeEnabled {
    return _testModeEnabled;
}

+ (void)setTestModeEnabled:(BOOL)enabled {
    _testModeEnabled = enabled;
}

static NSLocale *_locale = nil;
+ (NSLocale *)collationLocale {
    return _locale;
}

+ (void)setCollationLocale:(NSLocale *)locale {
    if (_locale) {
        [_locale release];
    }
    _locale = [locale retain];
}

static NSArray *_collationTableIndexTitles = nil;
+ (NSArray *)collationTableIndexTitles {
    return _collationTableIndexTitles;
}

+ (void)setCollationTableIndexTitles:(NSArray *)indexTitles {
    if (_collationTableIndexTitles) {
        [_collationTableIndexTitles release];
    }
    _collationTableIndexTitles = [indexTitles retain];
}

static NSArray *_sectionTitles = nil;
+ (NSArray *)sectionTitles {
    return _sectionTitles;
}

+ (void)setSectionTitles:(NSArray *)sectionTitles {
    if (_sectionTitles) {
        [_sectionTitles release];
    }
    _sectionTitles = [sectionTitles retain];
}

static NSArray *_sectionStartStrings = nil;
+ (NSArray *)sectionStartStrings {
    return _sectionStartStrings;
}

+ (void)setSectionStartStrings:(NSArray *)sectionStartStrings {
    if (_sectionStartStrings) {
        [_sectionStartStrings release];
    }
    _sectionStartStrings = [sectionStartStrings retain];
}

static UTransliterator *_transliterator = nil;
+ (UTransliterator *)transliterator {
    return _transliterator;
}

+ (void)setTransliterator:(UTransliterator *)transliterator {
    _transliterator = transliterator;
}

static NSArray *_sectionsForIndexTitles = nil;
+ (NSArray *)sectionsForIndexTitles {
    return _sectionsForIndexTitles;
}

+ (void)setSectionsForIndexTitles:(NSArray *)sectionsForIndexTitles {
    if (_sectionsForIndexTitles) {
        [_sectionsForIndexTitles release];
    }
    _sectionsForIndexTitles = [sectionsForIndexTitles retain];
}

@end
