//
//  UIColor+CydiaColors.m
//  Limitless
//
//  Created by George Dan on 30/11/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "UIColor+CydiaColors.h"

@implementation UIColor (CydiaColors)

+ (UIColor*) cydia_blue {
	return [UIColor colorWithRed:0.2 green:0.2 blue:1.0 alpha:1];
}

+ (UIColor*) cydia_blueish {
	return [UIColor colorWithRed:25/255 green:50/255 blue:80/255 alpha:1];
}

+ (UIColor*) cydia_folder {
	return [UIColor colorWithRed:142/255 green:142/255 blue:147/255 alpha:1];
}

+ (UIColor*) cydia_off {
	return [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
}

+ (UIColor*) cydia_gray {
	return [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
}

+ (UIColor*) cydia_green {
	return [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1];
}

+ (UIColor*) cydia_purple {
	return [UIColor colorWithRed:0.0 green:0.0 blue:0.7 alpha:1];
}

+ (UIColor*) cydia_purplish {
	return [UIColor colorWithRed:0.4 green:0.4 blue:0.8 alpha:1];
}

+ (UIColor*) cydia_installingColor {
	return [UIColor colorWithRed:0.88 green:1.0 blue:0.88 alpha:1];
}

+ (UIColor*) cydia_removingColor {
	return [UIColor colorWithRed:1.0 green:0.88 blue:0.88 alpha:1];
}

@end
