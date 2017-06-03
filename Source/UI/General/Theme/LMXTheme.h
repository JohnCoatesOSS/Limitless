//
//  LMXTheme.h
//  Limitless
//
//  Created on 4/19/17.
//

#import <Foundation/Foundation.h>

@interface LMXTheme : NSObject

// Colors

@property (class, nonatomic, readonly) UIColor *cellColorLabelImportant;
@property (class, nonatomic, readonly) UIColor *cellColorLabelUnimportant;

// Fonts

@property (class, nonatomic, readonly) UIFont *cellFontImportant;
@property (class, nonatomic, readonly) UIFont *cellFontUnimportant;

@end
