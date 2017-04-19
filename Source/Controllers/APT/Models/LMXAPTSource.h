//
//  LMXAPTSource.h
//  Limitless
//
//  Created on 12/5/16.
//

@interface LMXAPTSource : NSObject

@property (retain, strong) NSString *name;

@property BOOL isTrusted;
@property (retain, strong) NSURL *uri;
@property (retain, strong) NSURL *icon;
@property (retain, strong) NSURL *origin;
@property (retain, strong) NSURL *depiction;
@property (retain, strong) NSURL *descriptionURL;
@property (retain, strong) NSString *support;
@property (retain, strong) NSString *version;
@property (retain, strong) NSString *type;

@property (retain, strong) NSString *host;
@property (retain, strong) NSString *authority;

@property (retain, strong) NSString *distribution;

@property (retain, strong) NSURL *releaseBaseURL;
@property (retain, strong) NSArray<NSString *> *files;

@property (nonatomic) NSURL *iconURL;

@end
