//
//  Paths.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Paths : NSObject

+ (NSString *)applicationLibraryDirectory;
+ (NSString *)varLibCydiaDirectory;
+ (NSString *)etcAptDirectory;
+ (NSString *)cacheState;
+ (NSString *)savedState;
+ (NSString *)sourcesList;
+ (NSString *)cacheFile:(NSString *)filename;
+ (NSString *)documentsFile:(NSString *)filename;
+ (NSString *)dpkgStatus;

+ (NSString *)cacheDirectory;

+ (void)createDirectoryIfDoesntExist:(NSString *)directory;
@end
