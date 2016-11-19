//
//  APTManager.h
//  Cydia
//
//  Created by John Coates on 11/18/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APTManager : NSObject

+ (instancetype)sharedInstance;
- (void)setup;

@end
