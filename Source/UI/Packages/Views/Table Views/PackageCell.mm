//
//  PackageCell.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "PackageCell.h"
#import "DisplayHelpers.hpp"
#import "Source.h"


@implementation PackageCell

- (PackageCell *) init {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Package"]) != nil) {
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);
        
        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content addSubview:content_];
        
        [content_ setDelegate:self];
        [content_ setOpaque:YES];
    } return self;
}

- (NSString *) accessibilityLabel {
    return name_;
}

- (void) setPackage:(Package *)package asSummary:(bool)summary {
    summarized_ = summary;
    
    icon_ = nil;
    name_ = nil;
    description_ = nil;
    source_ = nil;
    badge_ = nil;
    placard_ = nil;
    
    if (package == nil) {
        [content_ setBackgroundColor:[UIColor whiteColor]];
    } else {
        [package parse];
        
        Source *source = [package source];
        
        icon_ = [package icon];
        
        if (NSString *name = [package name])
            name_ = [NSString stringWithString:name];
        
        if (NSString *description = [package shortDescription])
            description_ = [NSString stringWithString:description];
        
        commercial_ = [package isCommercial];
        
        NSString *label = nil;
        bool trusted = false;
        
        if (source != nil) {
            label = [source label];
            trusted = [source trusted];
        } else if ([[package id] isEqualToString:@"firmware"])
            label = UCLocalize("APPLE");
        else
            label = [NSString stringWithFormat:UCLocalize("SLASH_DELIMITED"), UCLocalize("UNKNOWN"), UCLocalize("LOCAL")];
        
        NSString *from(label);
        
        NSString *section = [package simpleSection];
        if (section != nil && ![section isEqualToString:label]) {
            section = [[NSBundle mainBundle] localizedStringForKey:section value:nil table:@"Sections"];
            from = [NSString stringWithFormat:UCLocalize("PARENTHETICAL"), from, section];
        }
        
        source_ = [NSString stringWithFormat:UCLocalize("FROM"), from];
        
        if (NSString *purpose = [package primaryPurpose])
            badge_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/Purposes/%@.png", App_, purpose]];
        
        UIColor *color;
        NSString *placard;
        
        if (NSString *mode = [package mode]) {
            if ([mode isEqualToString:@"REMOVE"] || [mode isEqualToString:@"PURGE"]) {
                color = [UIColor cydia_removingColor];
                placard = @"removing";
            } else {
                color = [UIColor cydia_installingColor];
                placard = @"installing";
            }
        } else {
            if (UIColor.isDarkModeEnabled) {
                color = [UIColor cydia_black];
            } else {
                color = [UIColor whiteColor];
            }
            
            if ([package installed] != nil)
                placard = @"installed";
            else
                placard = nil;
        }
        
        [content_ setBackgroundColor:color];
        
        if (placard != nil)
            placard_ = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/%@.png", App_, placard]];
    }
    
    [self setNeedsDisplay];
    [content_ setNeedsDisplay];
}

- (void) drawSummaryContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width([self bounds].size.width);
    
    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];
        
        while (rect.size.width > 16 || rect.size.height > 16) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }
        
        rect.origin.x = 19 - rect.size.width / 2;
        rect.origin.y = 19 - rect.size.height / 2;
        
        [icon_ drawInRect:Retina(rect)];
    }
    
    if (badge_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) badge_ size];
        
        rect.size.width /= 4;
        rect.size.height /= 4;
        
        rect.origin.x = 25 - rect.size.width / 2;
        rect.origin.y = 25 - rect.size.height / 2;
        
        [badge_ drawInRect:Retina(rect)];
    }
    
    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor([UIColor whiteColor].CGColor);
	
	NSMutableParagraphStyle *truncatingStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[truncatingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	if (!highlighted) {
        UISetColor(commercial_ ? [UIColor cydia_commercialColor].CGColor : [UIColor blackColor].CGColor);
		[name_ drawInRect:CGRectMake(36, 8, width - (placard_ == nil ? 68 : 94), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName:Font18Bold_,NSParagraphStyleAttributeName: truncatingStyle, NSForegroundColorAttributeName: (commercial_ ? [UIColor cydia_commercialColor] : [UIColor blackColor])}];
	} else {
		[name_ drawInRect:CGRectMake(36, 8, width - (placard_ == nil ? 68 : 94), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName:Font18Bold_,NSParagraphStyleAttributeName: truncatingStyle}];
	}
    
    if (placard_ != nil)
        [placard_ drawAtPoint:CGPointMake(width - 52, 11)];
}

- (void) drawNormalContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width([self bounds].size.width);
    
    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];
        
        while (rect.size.width > 32 || rect.size.height > 32) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }
        
        rect.origin.x = 25 - rect.size.width / 2;
        rect.origin.y = 25 - rect.size.height / 2;
        
        [icon_ drawInRect:Retina(rect)];
    }
    
    if (badge_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) badge_ size];
        
        rect.size.width /= 2;
        rect.size.height /= 2;
        
        rect.origin.x = 36 - rect.size.width / 2;
        rect.origin.y = 36 - rect.size.height / 2;
        
        [badge_ drawInRect:Retina(rect)];
    }
    
    if (highlighted && kCFCoreFoundationVersionNumber < 800) {
        UISetColor([UIColor whiteColor].CGColor);
    }
    
    if (!highlighted)
        UISetColor(commercial_ ? [UIColor cydia_commercialColor].CGColor : [UIColor blackColor].CGColor);
	
	NSMutableParagraphStyle *truncatingStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[truncatingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
    [name_ drawInRect:CGRectMake(48, 8, (width - (placard_ == nil ? 80 : 106)), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font18Bold_, NSParagraphStyleAttributeName: truncatingStyle, NSForegroundColorAttributeName: (commercial_ ? [UIColor cydia_commercialColor] : [UIColor blackColor])}];
	[source_ drawInRect:CGRectMake(58, 29, (width - 29), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font12_, NSParagraphStyleAttributeName: truncatingStyle, NSForegroundColorAttributeName: (commercial_ ? [UIColor cydia_commercialColor] : [UIColor blackColor])}];
    
	if (!highlighted) {
        UISetColor(commercial_ ? [UIColor cydia_commercialVariantColor].CGColor : [UIColor cydia_grayColor].CGColor);
		[description_ drawInRect:CGRectMake(12, 46, (width - 46), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font14_, NSParagraphStyleAttributeName: truncatingStyle, NSForegroundColorAttributeName: (commercial_ ? [UIColor cydia_commercialVariantColor] : [UIColor cydia_grayColor])}];
    } else {
        [description_ drawInRect:CGRectMake(12, 46, (width - 46), CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font14_, NSParagraphStyleAttributeName: truncatingStyle}];
    }
    
    if (placard_ != nil) {
        [placard_ drawAtPoint:CGPointMake(width - 52, 9)];
    }
}

- (void) drawContentRect:(CGRect)rect {
    if (summarized_) {
        [self drawSummaryContentRect:rect];
    } else {
        [self drawNormalContentRect:rect];
    }
}

@end
