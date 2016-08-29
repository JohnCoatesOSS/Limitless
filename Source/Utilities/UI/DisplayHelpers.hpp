//
//  DisplayHelpers.hpp
//  Cydia
//
//  Created on 8/29/16.
//

#import "CyteKit.h"
#import "UIGlobals.h"

// Globals
extern bool IsWildcat_;
extern CGFloat ScreenScale_;
static NSString *Idiom_;

static const NSUInteger UIViewAutoresizingFlexibleBoth(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

CGFloat CYStatusBarHeight();

inline float Interpolate(float begin, float end, float fraction) {
    return (end - begin) * fraction + begin;
}

static inline double Retina(double value) {
    value *= ScreenScale_;
    value = round(value);
    value /= ScreenScale_;
    return value;
}

static inline CGRect Retina(CGRect value) {
    value.origin.x *= ScreenScale_;
    value.origin.y *= ScreenScale_;
    value.size.width *= ScreenScale_;
    value.size.height *= ScreenScale_;
    value = CGRectIntegral(value);
    value.origin.x /= ScreenScale_;
    value.origin.y /= ScreenScale_;
    value.size.width /= ScreenScale_;
    value.size.height /= ScreenScale_;
    return value;
}

static _finline const char *StripVersion_(const char *version) {
    const char *colon(strchr(version, ':'));
    return colon == NULL ? version : colon + 1;
}


NSString *LocalizeSection(NSString *section);

NSString *Simplify(NSString *title);


// Collation

#define CUC const ustring &str(*reinterpret_cast<const ustring *>(rep))
#define UC ustring &str(*reinterpret_cast<ustring *>(rep))
static struct UReplaceableCallbacks CollationUCalls_ = {
    .length = [](const UReplaceable *rep) -> int32_t { CUC;
        return str.size();
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
