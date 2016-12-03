//
//  UIColor+CydiaColors.m
//  Limitless
//
//  Created by George Dan on 30/11/16.
//  
//

#import "UIColor+CydiaColors.h"

@implementation UIColor (CydiaColors)

+ (UIColor*) cydia_blueColor {
	return [UIColor colorWithRed:0.2 green:0.2 blue:1.0 alpha:1];
}

+ (UIColor*) cydia_blueVariantColor {
	return [UIColor colorWithRed:25/255 green:50/255 blue:80/255 alpha:1];
}

+ (UIColor*) cydia_folderColor {
	return [UIColor colorWithRed:142/255 green:142/255 blue:147/255 alpha:1];
}

+ (UIColor*) cydia_offColor {
	return [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
}

+ (UIColor*) cydia_grayColor {
	return [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
}

+ (UIColor*) cydia_greenColor {
	return [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1];
}

+ (UIColor*) cydia_commercialColor {
	return [UIColor colorWithRed:0.0 green:0.0 blue:0.7 alpha:1];
}

+ (UIColor*) cydia_commercialVariantColor {
	return [UIColor colorWithRed:0.4 green:0.4 blue:0.8 alpha:1];
}

+ (UIColor*) cydia_installingColor {
	return [UIColor colorWithRed:0.88 green:1.0 blue:0.88 alpha:1];
}

+ (UIColor*) cydia_removingColor {
	return [UIColor colorWithRed:1.0 green:0.88 blue:0.88 alpha:1];
}

+ (UIColor*) cydia_tintColor {
    return [UIColor colorWithRed:0.21 green:0.20 blue:0.21 alpha:1.0];
}

+ (UIColor*) cydia_black {
    return [UIColor colorWithRed:0.09 green:0.08 blue:0.09 alpha:1.0];
}

+ (BOOL) isDarkModeEnabled {
    return YES;
}

@end

/*
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
*/
