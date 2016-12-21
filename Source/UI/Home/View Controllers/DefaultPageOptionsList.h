//
//  DefaultPageOptionsList.h
//  Limitless
//
//  Created by Shade Zepheri on 12/10/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DefaultPageOptionsList : UIViewController
<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *table;

@end

