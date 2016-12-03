//
//  SectionCell.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "SectionCell.h"
#import "iPhonePrivate.h"
#import "DisplayHelpers.hpp"
#import "UIColor+CydiaColors.h"

@implementation SectionCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
        icon_ = [UIImage imageNamed:@"folder.png"];
        // XXX: this initial frame is wrong, but is fixed later
        switch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(218, 9, 60, 25)] autorelease];
        [switch_ addTarget:self action:@selector(onSwitch:) forEvents:UIControlEventValueChanged];
        
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);
        
        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content addSubview:content_];
        if (UIColor.isDarkModeEnabled) {
            [content_ setBackgroundColor:[UIColor cydia_tintColor]];
        } else {
            [content_ setBackgroundColor:[UIColor whiteColor]];
        }
        
        [content_ setDelegate:self];
    } return self;
}

- (void) onSwitch:(id)sender {
    NSMutableDictionary *metadata([Sections_ objectForKey:basic_]);
    if (metadata == nil) {
        metadata = [NSMutableDictionary dictionaryWithCapacity:2];
        [Sections_ setObject:metadata forKey:basic_];
    }
    
    [metadata setObject:[NSNumber numberWithBool:([switch_ isOn] == NO)] forKey:@"Hidden"];
}

- (void) setSection:(Section *)section editing:(BOOL)editing {
    if (editing != editing_) {
        if (editing_)
            [switch_ removeFromSuperview];
        else
            [self addSubview:switch_];
        editing_ = editing;
    }
    
    basic_ = nil;
    section_ = nil;
    name_ = nil;
    count_ = nil;
    
    if (section == nil) {
        name_ = UCLocalize("ALL_PACKAGES");
        count_ = nil;
    } else {
        basic_ = [section name];
        section_ = [section localized];
        
        name_  = section_ == nil || [section_ length] == 0 ? UCLocalize("NO_SECTION") : (NSString *) section_;
        count_ = [NSString stringWithFormat:@"%zd", [section count]];
        
        if (editing_)
            [switch_ setOn:(isSectionVisible(basic_) ? 1 : 0) animated:NO];
    }
    
    [self setAccessoryType:editing ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator];
    [self setSelectionStyle:editing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue];
    
    [content_ setNeedsDisplay];
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGRect rect([switch_ frame]);
    [switch_ setFrame:CGRectMake(frame.size.width - rect.size.width - 9, 9, rect.size.width, rect.size.height)];
}

- (NSString *) accessibilityLabel {
    return name_;
}

- (void) drawContentRect:(CGRect)rect {
    bool highlighted(highlighted_ && !editing_);
    
    [icon_ drawInRect:CGRectMake(7, 7, 32, 32)];
    
    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor([UIColor whiteColor].CGColor);
    
    float width(rect.size.width);
    if (editing_)
        width -= 9 + [switch_ frame].size.width;
    
	if (!highlighted) {
        UISetColor([UIColor blackColor].CGColor);
		
		NSMutableParagraphStyle *truncatingStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
		[truncatingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		[name_ drawInRect:CGRectMake(48, 12, width-58, CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font18Bold_, NSForegroundColorAttributeName:[UIColor blackColor], NSParagraphStyleAttributeName: truncatingStyle}];
	} else {
		
		NSMutableParagraphStyle *truncatingStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
		[truncatingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		[name_ drawInRect:CGRectMake(48, 12, width-58, CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font18Bold_, NSParagraphStyleAttributeName: truncatingStyle}];
	}
	
    
	CGSize size = [count_ sizeWithAttributes:@{NSFontAttributeName: Font14_}];
    
    UISetColor([UIColor cydia_folderColor].CGColor);
    if (count_ != nil)
		[count_ drawInRect:CGRectMake(Retina(10 + (30 - size.width) / 2), 18, CGFLOAT_MAX, CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font12Bold_, NSForegroundColorAttributeName: [UIColor cydia_folderColor]}];
}

@end
