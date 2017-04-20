//
//  APTSourcesManager.h
//  Limitless
//
//  Created on 4/19/17.
//

#import <Foundation/Foundation.h>

@interface APTSourcesManager : NSObject

@property (class, nonatomic, readonly) APTSourcesManager *sharedInstance;

@property (readonly) NSDictionary *sources;

- (void)addSource:(NSURL *)sourceURL;
- (void)writeSources;

@end
