//
//  Paths.h
//  Cydia
//
//  Created on 8/31/16.
//

#import <Foundation/Foundation.h>

@interface Paths : NSObject

@property (class, readonly) NSURL *applicationDirectory;
@property (class, readonly) NSURL *applicationBinary;

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
