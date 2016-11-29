#import <UIKit/UIKit.h>
// Define trickery to make classses defines for macOS available to iOS

#pragma push_macro("NS_CLASS_AVAILABLE_MAC")
#undef NS_CLASS_AVAILABLE_MAC
#define NS_CLASS_AVAILABLE_MAC(_mac) NS_CLASS_AVAILABLE(_mac, 2_0)

#pragma push_macro("NS_AVAILABLE_MAC")
#undef NS_AVAILABLE_MAC
#define NS_AVAILABLE_MAC(_mac) CF_AVAILABLE(_mac, 2_0)

#pragma push_macro("NS_ENUM_AVAILABLE_MAC")
#undef NS_ENUM_AVAILABLE_MAC
#define NS_ENUM_AVAILABLE_MAC(_mac) CF_ENUM_AVAILABLE(_mac, 2_0)

#define NSView UIView
#define NSWindow UIWindow
#define NSImage UIImage

#define NSRect CGRect
#define NSSize CGSize
#define NSPoint CGPoint

#define NSUserInterfaceValidations NSObject
#define NSSelectionAffinity NSInteger
#define NSPasteboard NSObject
