//
//  SourceCell.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "SourceCell.h"
#import "Source.h"
#import "DisplayHelpers.hpp"

@implementation SourceCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
        UIView *content([self contentView]);
        CGRect bounds([content bounds]);
        
        content_ = [[[CyteTableViewCellContentView alloc] initWithFrame:bounds] autorelease];
        [content_ setAutoresizingMask:UIViewAutoresizingFlexibleBoth];
        [content_ setBackgroundColor:[UIColor whiteColor]];
        [content addSubview:content_];
        
        [content_ setDelegate:self];
        [content_ setOpaque:YES];
        
        indicator_ = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGraySmall] autorelease];
        [indicator_ setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];// | UIViewAutoresizingFlexibleBottomMargin];
        [content addSubview:indicator_];
        
        [[content_ layer] setContentsGravity:kCAGravityTopLeft];
    } return self;
}


- (void) _setImage:(NSArray *)data {
    if ([url_ isEqual:[data objectAtIndex:0]]) {
        icon_ = [data objectAtIndex:1];
        [content_ setNeedsDisplay];
    }
}

- (void) _setSource:(NSURL *) url {
    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);
    
    if (NSData *data = [NSURLConnection
                        sendSynchronousRequest:[NSURLRequest
                                                requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:10
                                                ]
                        
                        returningResponse:NULL
                        error:NULL
                        ])
        if (UIImage *image = [UIImage imageWithData:data])
            [self performSelectorOnMainThread:@selector(_setImage:) withObject:[NSArray arrayWithObjects:url, image, nil] waitUntilDone:NO];
    
    [pool release];
}

- (void) setSource:(Source *)source {
    source_ = source;
    [source_ setDelegate:self];
    
    [self setFetch:[NSNumber numberWithBool:[source_ fetch]]];
    
    icon_ = [UIImage imageNamed:@"unknown.png"];
    
    origin_ = [source name];
    label_ = [source rooturi];
    
    [content_ setNeedsDisplay];
    
    url_ = [source iconURL];
    [NSThread detachNewThreadSelector:@selector(_setSource:) toTarget:self withObject:url_];
}

- (void) setAllSource {
    source_ = nil;
    [indicator_ stopAnimating];
    
    icon_ = [UIImage imageNamed:@"folder.png"];
    origin_ = UCLocalize("ALL_SOURCES");
    label_ = UCLocalize("ALL_SOURCES_EX");
    [content_ setNeedsDisplay];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    UIView *content([self contentView]);
    CGRect bounds([content bounds]);
    
    CGRect frame([indicator_ frame]);
    frame.origin.x = bounds.size.width - frame.size.width;
    frame.origin.y = Retina((bounds.size.height - frame.size.height) / 2);
    
    if (kCFCoreFoundationVersionNumber < 800)
        frame.origin.x -= 8;
    [indicator_ setFrame:frame];
}

- (NSString *) accessibilityLabel {
    return origin_;
}

- (void) drawContentRect:(CGRect)rect {
    bool highlighted(highlighted_);
    float width(rect.size.width);
    
    if (icon_ != nil) {
        CGRect rect;
        rect.size = [(UIImage *) icon_ size];
        
        while (rect.size.width > 32 || rect.size.height > 32) {
            rect.size.width /= 2;
            rect.size.height /= 2;
        }
        
        rect.origin.x = 26 - rect.size.width / 2;
        rect.origin.y = 26 - rect.size.height / 2;
        
        [icon_ drawInRect:Retina(rect)];
    }
    
    if (highlighted && kCFCoreFoundationVersionNumber < 800)
        UISetColor(White_);
	
    if (!highlighted)
        UISetColor(Black_);
	
	NSMutableParagraphStyle *truncatingStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[truncatingStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	[origin_ drawInRect:CGRectMake(52, 8, width-49, CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font18Bold_, NSParagraphStyleAttributeName: truncatingStyle}];
    
    if (!highlighted)
        UISetColor(Gray_);
	[label_ drawInRect:CGRectMake(52, 29, width-49, CGFLOAT_MAX) withAttributes:@{NSFontAttributeName: Font12_, NSParagraphStyleAttributeName: truncatingStyle, NSForegroundColorAttributeName: (!highlighted ? [UIColor colorWithCGColor:Gray_.color_]:[UIColor blackColor])}];
}

- (void) setFetch:(NSNumber *)fetch {
    if ([fetch boolValue])
        [indicator_ startAnimating];
    else
        [indicator_ stopAnimating];
}

@end
