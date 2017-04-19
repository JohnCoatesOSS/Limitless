//
//  LMXDevice.h
//  Limitless
//
//  Created by John Coates on 4/19/17.
//  Copyright © 2017 Limitless. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMXDevice : NSObject


@property (class, nonatomic, readonly) BOOL isSimulator;
@property (class, nonnull, nonatomic, readonly) NSString *uniqueIdentifier;
@property (class, nonnull, nonatomic, readonly) NSString *machineIdentifier;

@end
