//
//  Paths.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Paths : NSObject

+ (NSString *)sandboxDocumentsDirectory;
+ (NSString *)applicationLibraryDirectory;
+ (NSString *)varLibCydiaDirectory;

+ (NSString *)rootFile:(NSString *)filename;
+ (NSString *)documentsFile:(NSString *)filename;
+ (NSString *)cacheFile:(NSString *)filename;

+ (void)createDirectoryIfDoesntExist:(NSString *)directory;

@end

#import "Paths+APT.h"
#import "NSString+Paths.h"
