//
//  DefaultPageOptionsList.h
//  Limitless
//
//  Created on 12/10/16.
//

#import <UIKit/UIKit.h>

@interface DefaultPageOptionsList : UIViewController
<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *table;

@end

