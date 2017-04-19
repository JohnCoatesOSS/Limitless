//
//  APTManager.h
//  Cydia
//
//  11/18/16.
//  Copyright © 2016 Cydia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMXAPTSource;

@interface APTManager : NSObject

+ (instancetype)sharedInstance;
- (void)setup;

- (NSArray <LMXAPTSource *> *)readSourcesWithError:(NSError **)error;

// MARK: - Debug

- (BOOL)performUpdate;

@end
