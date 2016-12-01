## Code Style Guide

As the code stands now the style is very mixed. Cydia is coded in a non-standard style and we're moving it away from a C++/Objective-C++ mixed project to a modern Objective-C project.

### Variable Names
All variables should be named in camelCase, with no abbreviations.

### Instance Variables
Instance variables should only be private, and not included in header files.

**Preferred:**

*CydiaLoadingView.m*

````
@interface CydiaLoadingView() {
    UIActivityIndicatorView *_spinner;
}

@end
````

**Not Preferred:**

*CydiaLoadingView.h*
````
@interface CydiaLoadingView : UIView {
    UIActivityIndicatorView *_spinner;
}

@end
````

### Class Variables
Class variables were introduced in Xcode 8. They're a convenient replacement for globals.

**Example:**
*LMXLocalizedTableSections.h*
````
@interface LMXLocalizedTableSections : NSObject
@property (class, readonly) NSArray <NSNumber *> *sectionsForIndexTitles;
@end
````

*LMXLocalizedTableSections.m*
````
@interface LMXLocalizedTableSections ()
@property (class, retain) NSArray <NSNumber *> *sectionsForIndexTitles;

@end

@implementation LMXLocalizedTableSections
static NSArray <NSNumber *> *_sectionsForIndexTitles = nil;
+ (NSArray <NSNumber *> *)sectionsForIndexTitles {
    return _sectionsForIndexTitles;
}

+ (void)setSectionsForIndexTitles:(NSArray <NSNumber *> *)sectionsForIndexTitles {
    if (_sectionsForIndexTitles) {
        [_sectionsForIndexTitles release];
    }
    _sectionsForIndexTitles = [sectionsForIndexTitles retain];
}
@end
````
### Global Variables
No global variables should be used. They should be wrapped into a class variable instead.

Other style guides for inspiration:

* https://github.com/raywenderlich/objective-c-style-guide
* https://github.com/NYTimes/objective-c-style-guide
* https://github.com/github/objective-c-style-guide
* https://google.github.io/styleguide/objcguide.xml
* https://trac.adium.im/wiki/CodingStyle
* https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html
* https://github.com/markeissler/wonderful-objective-c-style-guide
* http://dynamit.github.io/code-standards/standards/mobile/objc.html
