//
//  Paths.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Paths : NSObject

+ (NSString *)applicationLibraryDirectory;
+ (NSString *)varLibCydiaDirectory;
+ (NSString *)cacheState;
+ (NSString *)savedState;
+ (NSString *)sourcesList;
@end
