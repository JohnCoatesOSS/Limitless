//
//  LMXSourceCell.h
//  Limitless
//
//  Created on 12/5/16.
//

@class APTSource;

@interface LMXSourceCell : UITableViewCell

@property (nullable, nonatomic, copy) APTSource *source;
@property (nonatomic) BOOL allSources;
@property (nonatomic) BOOL isLoading;

@end
