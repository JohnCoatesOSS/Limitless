//
//  Package.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "Standard.h"
#import "Apt.h"
#import "CYString.hpp"
#import "Database.h"
#import "CytoreHelpers.h"
#import "MimeAddress.h"
#import "Profiling.hpp"
#import "Unicode.h"
#import "NSString+Cydia.hpp"

struct ParsedPackage {
    CYString md5sum_;
    CYString tagline_;
    
    CYString architecture_;
    CYString icon_;
    
    CYString depiction_;
    CYString homepage_;
    CYString author_;
    
    CYString support_;
};

@interface Package : NSObject {
    uint32_t era_ : 25;
@public uint32_t role_ : 3;
    uint32_t essential_ : 1;
    uint32_t obsolete_ : 1;
    uint32_t ignored_ : 1;
    uint32_t pooled_ : 1;
    
    CYPool *pool_;
    
    uint32_t rank_;
    
    _transient Database *database_;
    
    pkgCache::VerIterator version_;
    pkgCache::PkgIterator iterator_;
    pkgCache::VerFileIterator file_;
    
    CYString id_;
    CYString name_;
    CYString transform_;
    
    CYString latest_;
    CYString installed_;
    time_t upgraded_;
    
    const char *section_;
    _transient NSString *section$_;
    
    _H<Source> source_;
    
    PackageValue *metadata_;
    ParsedPackage *parsed_;
    
    _H<NSMutableArray> tags_;
}

- (Package *) initWithVersion:(pkgCache::VerIterator)version withZone:(NSZone *)zone inPool:(CYPool *)pool database:(Database *)database;
+ (Package *) packageWithIterator:(pkgCache::PkgIterator)iterator withZone:(NSZone *)zone inPool:(CYPool *)pool database:(Database *)database;

- (pkgCache::PkgIterator) iterator;
- (void) parse;

- (NSArray *) downgrades;

- (NSString *) section;
- (NSString *) simpleSection;

- (NSString *) longSection;
- (NSString *) shortSection;

- (NSString *) uri;

- (MIMEAddress *) maintainer;
- (size_t) size;
- (NSString *) longDescription;
- (NSString *) shortDescription;
- (unichar) index;

- (PackageValue *) metadata;
- (time_t) seen;

- (bool) subscribed;
- (bool) setSubscribed:(bool)subscribed;

- (BOOL) ignored;
- (bool)isFavorited;

- (NSString *) latest;
- (NSString *) installed;
- (BOOL) uninstalled;

- (BOOL) upgradableAndEssential:(BOOL)essential;
- (BOOL) essential;
- (BOOL) broken;
- (BOOL) unfiltered;
- (BOOL) visible;

- (BOOL) half;
- (BOOL) halfConfigured;
- (BOOL) halfInstalled;
- (BOOL) hasMode;
- (NSString *) mode;

- (NSString *) id;
- (NSString *) name;
- (UIImage *) icon;
- (NSString *) homepage;
- (NSString *) depiction;
- (MIMEAddress *) author;

- (NSString *) support;

- (NSArray *) files;
- (NSArray *) warnings;
- (NSArray *) applications;

- (Source *) source;

- (time_t) upgraded;
- (uint32_t) recent;

- (uint32_t) rank;
- (BOOL) matches:(NSArray *)query;

- (BOOL) hasTag:(NSString *)tag;
- (NSString *) primaryPurpose;
- (NSArray *) purposes;
- (bool) isCommercial;

- (void) setIndex:(size_t)index;

- (CYString &) cyname;

- (uint32_t) compareBySection:(NSArray *)sections;

- (void) clear;
- (void) install;
- (void) remove;

@end

static inline uint32_t PackageChangesRadix(Package *self, void *) {
    union {
        uint32_t key;
        
        struct {
            uint32_t timestamp : 30;
            uint32_t ignored : 1;
            uint32_t upgradable : 1;
        } bits;
    } value;
    
    bool upgradable([self upgradableAndEssential:YES]);
    value.bits.upgradable = upgradable ? 1 : 0;
    
    if (upgradable) {
        value.bits.timestamp = 0;
        value.bits.ignored = [self ignored] ? 0 : 1;
        value.bits.upgradable = 1;
    } else {
        value.bits.timestamp = [self seen] >> 2;
        value.bits.ignored = 0;
        value.bits.upgradable = 0;
    }
    
    return _not(uint32_t) - value.key;
}


extern CYString &(*PackageName)(Package *self, SEL sel);

static inline uint32_t PackagePrefixRadix(Package *self, void *context) {
    size_t offset(reinterpret_cast<size_t>(context));
    CYString &name(PackageName(self, @selector(cyname)));
    
    size_t size(name.size());
    if (size == 0)
        return 0;
    char *text(name.data());
    
    size_t zeros;
    if (!isdigit(text[0]))
        zeros = 0;
    else {
        size_t digits(1);
        while (size != digits && isdigit(text[digits]))
            if (++digits == 4)
                break;
        zeros = 4 - digits;
    }
    
    uint8_t data[4];
    
    if (offset == 0 && zeros != 0) {
        memset(data, '0', zeros);
        memcpy(data + zeros, text, 4 - zeros);
    } else {
        /* XXX: there's some danger here if you request a non-zero offset < 4 and it gets zero padded */
        if (size <= offset - zeros)
            return 0;
        
        text += offset - zeros;
        size -= offset - zeros;
        
        if (size >= 4)
            memcpy(data, text, 4);
        else {
            memcpy(data, text, size);
            memset(data + size, 0, 4 - size);
        }
        
        for (size_t i(0); i != 4; ++i)
            if (isalpha(data[i]))
                data[i] |= 0x20;
    }
    
    if (offset == 0) {
        if (data[0] == '@') {
            data[0] = 0x7f;
        }
        else {
            data[0] = (data[0] & 0x1f) | "\x80\x00\xc0\x40"[data[0] >> 6];
        }
    }
    
    /* XXX: ntohl may be more honest */
    return OSSwapInt32(*reinterpret_cast<uint32_t *>(data));
}

static inline CFComparisonResult StringNameCompare(CFStringRef lhn, CFStringRef rhn, size_t length) {
    _profile(PackageNameCompare)
    if (lhn == NULL)
        return rhn == NULL ? kCFCompareEqualTo : kCFCompareLessThan;
    else if (rhn == NULL)
        return kCFCompareGreaterThan;
    
    CFIndex length(CFStringGetLength(lhn));
    
    _profile(PackageNameCompare$NumbersLast)
    if (length != 0 && CFStringGetLength(rhn) != 0) {
        UniChar lhc(CFStringGetCharacterAtIndex(lhn, 0));
        UniChar rhc(CFStringGetCharacterAtIndex(rhn, 0));
        bool lha(CFUniCharIsMemberOf(lhc, kCFUniCharLetterCharacterSet));
        if (lha != CFUniCharIsMemberOf(rhc, kCFUniCharLetterCharacterSet))
            return lha ? kCFCompareLessThan : kCFCompareGreaterThan;
    }
    _end
    
    _profile(PackageNameCompare$Compare)
    return CFStringCompareWithOptionsAndLocale(lhn, rhn, CFRangeMake(0, length), LaxCompareFlags_, (CFLocaleRef) (id) CollationLocale_);
    _end
    _end
}

_finline CFComparisonResult StringNameCompare(NSString *lhn, NSString*rhn, size_t length) {
    return StringNameCompare((CFStringRef) lhn, (CFStringRef) rhn, length);
}

static inline CFComparisonResult PackageNameCompare(Package *lhs, Package *rhs, void *arg) {
    CYString &lhn(PackageName(lhs, @selector(cyname)));
    NSString *rhn(PackageName(rhs, @selector(cyname)));
    return StringNameCompare(lhn, rhn, lhn.size());
}

static inline CFComparisonResult PackageNameCompare_(Package **lhs, Package **rhs, void *arg) {
    return PackageNameCompare(*lhs, *rhs, arg);
}

struct PackageNameOrdering :
std::binary_function<Package *, Package *, bool>
{
    _finline bool operator ()(Package *lhs, Package *rhs) const {
        return PackageNameCompare(lhs, rhs, NULL) == kCFCompareLessThan;
    }
};
