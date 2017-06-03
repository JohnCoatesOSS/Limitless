//
//  APTSourcesManager.m
//  Limitless
//
//  Created on 4/19/17.
//

#import "APTSourcesManager.h"
#import "Paths.h"

@interface APTSourcesManager ()
    @property (readwrite) NSDictionary *sources;
@end

@implementation APTSourcesManager

// MARK: - Shared Instance

+ (instancetype)sharedInstance {
    static APTSourcesManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [APTSourcesManager new];
    });
    return instance;
}

// MARK: - Init

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self readSources];
    }
    
    return self;
}

- (BOOL)readSources {
    if ([self readSourcesFromUserDefaults]) {
        return TRUE;
    }
    
    if ([self readSourcesFromMetadata]) {
        return TRUE;
    }
    
    _sources = @{};
    
    return FALSE;
}

- (BOOL)readSourcesFromUserDefaults {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.saurik.Cydia"];
    
    _sources = [defaults objectForKey:@"CydiaSources"];
    NSLog(@"user default sources: %@", _sources);
    
    if (!_sources) {
        return FALSE;
    }
    
    
    return TRUE;
}

- (BOOL)readSourcesFromMetadata {
    NSString *path = [[Paths varLibCydiaDirectory] stringByAppendingPathComponent:@"metadata.plist"];
    NSDictionary *metadata = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (!metadata) {
        NSLog(@"Error: Couldn't read metadata plist file at: %@", path);
        return FALSE;
    }
    
    _sources = metadata[@"Sources"];
    NSLog(@"Metadata sources: %@", _sources);
    
    if (!_sources) {
        return FALSE;
    }
    
    return TRUE;
    
}

// MARK: - Adding/Removing

static NSString * const kType = @"Type";
static NSString * const kURI = @"URI";
static NSString * const kDistribution = @"Distribution";
static NSString * const kSections = @"Sections";

- (void)addSource:(NSURL *)sourceURL {
    NSString *type = @"deb";
    NSString *URI = sourceURL.absoluteString;
    NSString *distribution = @"./";
    NSArray *sections = @[];
    
    NSDictionary *source;
    source = @{
               kType: type,
               kURI: URI,
               kDistribution: distribution,
               kSections: sections
               };
    
    NSMutableDictionary *mutableSources = [self.sources mutableCopy];
    NSString *key = [NSString stringWithFormat:@"%@:%@:%@", type, URI, distribution];
    mutableSources[key] = source;
    
    self.sources = mutableSources;
}

- (void)writeSources {
    [self syncSourcesWithLegacyGlobal];
    
    NSString *cydiaLine = [NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",
                           kCFCoreFoundationVersionNumber];
    
    NSString *contents = cydiaLine;
    NSDictionary *sources = self.sources;
    for (NSString *key in sources) {
        NSDictionary *source = sources[key];
        NSArray *sections = source[kSections];
        
        NSString *sectionsString = @"";
        if (sections.count > 0) {
            sectionsString = [sections componentsJoinedByString:@" "];
            sectionsString = [@" " stringByAppendingString:sectionsString];
        }
        
        contents = [contents stringByAppendingFormat:@"%@ %@ %@%@\n",
                    source[kType], source[kURI], source[kDistribution],
                    sectionsString];
    }
    
    NSString *sourcesListPath = [Paths.aptEtc subpath:@"sources.list"];
    NSError *error = nil;
    [contents writeToFile:sourcesListPath
               atomically:TRUE
                 encoding:NSUTF8StringEncoding
                    error:&error];
    
    if (error) {
        [NSException raise:@"Couldn't write sources"
                    format:@"Couldn't write sources to %@: %@", sourcesListPath, error];
    }
}

- (void)syncSourcesWithLegacyGlobal {
#ifdef CYDIA_LEGACY_COMPATIBILITY
    extern NSDictionary *Sources_;
    Sources_ = self.sources;
#endif
}

@end
