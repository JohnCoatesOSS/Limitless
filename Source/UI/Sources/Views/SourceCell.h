//
//  SourceCell.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"
#import "Delegates.h"

@interface SourceCell : CyteTableViewCell
<CyteTableViewCellDelegate, SourceDelegate> {
    _H<Source, 1> source_;
    _H<NSURL> url_;
    _H<UIImage> icon_;
    _H<NSString> origin_;
    _H<NSString> label_;
    _H<UIActivityIndicatorView> indicator_;
}

- (void)setSource:(Source *)source;
- (void)setFetch:(NSNumber *)fetch;
- (void)setAllSource;

@end
