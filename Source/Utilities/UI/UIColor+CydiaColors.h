//
//  UIColor+CydiaColors.h
//  Limitless
//
//  Created by George Dan on 30/11/16.
//  
//

#import <UIKit/UIKit.h>

@interface UIColor (CydiaColors)
@property (class, readwrite) BOOL isDarkModeEnabled;
+ (UIColor*) cydia_blueColor;
+ (UIColor*) cydia_blueVariantColor;
+ (UIColor*) cydia_folderColor;
+ (UIColor*) cydia_offColor;
+ (UIColor*) cydia_grayColor;
+ (UIColor*) cydia_greenColor;
+ (UIColor*) cydia_commercialColor;
+ (UIColor*) cydia_commercialVariantColor;
+ (UIColor*) cydia_installingColor;
+ (UIColor*) cydia_removingColor;
+ (UIColor*) cydia_tintColor;
+ (UIColor*) cydia_black;
+ (UIColor*) cydia_darkTableViewCell;
+ (UIColor*) cydia_darkTableViewBackground;
+ (UIColor*) cydia_darkTableViewSeperator;
+ (UIColor*) cydia_darkTableViewCellSelection;
+ (UIColor*) cydia_darkInstallingColor;
+ (UIColor*) cydia_darkRemovingColor;
@end
