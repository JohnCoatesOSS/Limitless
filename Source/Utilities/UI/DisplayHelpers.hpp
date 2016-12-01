//
//  DisplayHelpers.hpp
//  Cydia
//
//  Created on 8/29/16.
//

#import "CyteKit.h"
#import "UIGlobals.h"
#import "Display.h"

static const NSUInteger UIViewAutoresizingFlexibleBoth(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

CGFloat CYStatusBarHeight();

inline float Interpolate(float begin, float end, float fraction) {
    return (end - begin) * fraction + begin;
}

static inline double Retina(double value) {
    return [Display pointRoundedAtScreenScale:value];
}

static inline CGRect Retina(CGRect value) {
    return [Display rectRoundedAtScreenScale:value];
}

static _finline const char *StripVersion_(const char *version) {
    const char *colon(strchr(version, ':'));
    return colon == NULL ? version : colon + 1;
}


NSString *LocalizeSection(NSString *section);

NSString *Simplify(NSString *title);



bool isSectionVisible(NSString *section);

// Web

NSUInteger DOMNodeList$countByEnumeratingWithState$objects$count$(DOMNodeList *self,
                                                                  SEL sel,
                                                                  NSFastEnumerationState *state,
                                                                  id *objects,
                                                                  NSUInteger count);
