//
//  LMXTheme.m
//  Limitless
//
//  Created on 4/19/17.
//

#import "LMXTheme.h"

@implementation LMXTheme

// MARK: - Colors

+ (UIColor *)cellColorLabelImportant {
    return UIColor.blackColor;
}

+ (UIColor *)cellColorLabelUnimportant {
    return [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
}

// MARK: - Fonts

+ (UIFont *)cellFontImportant {
    return [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
}

+ (UIFont *)cellFontUnimportant {
    return [UIFont systemFontOfSize:12];
}

@end
