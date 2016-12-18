//
//  APTManager.h
//  Cydia
//
//  11/18/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APTManager : NSObject

@property (class, nonatomic) BOOL debugMode;

+ (instancetype)sharedInstance;
- (void)setup;

// MARK: - Debug

+ (void)clearAPTState;

@end
