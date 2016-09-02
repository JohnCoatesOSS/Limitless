//
//  Startup.mm
//  Cydia
//
//  Created on 8/31/16.
//

#import <notify.h>

#import "System.h"
#import "iPhonePrivate.h"
#import "Substrate.hpp"
#import "Startup.h"
#import "SystemGlobals.h"
#import "CyteKit.h"
#import "GeneralGlobals.h"
#import "Networking.h"
#import "Package.h"
#import "DisplayHelpers.hpp"
#import "Defines.h"
#import "NSUserDefaults+Hooks.h"
#import "NSURLConnection+Hooks.h"
#import "WAKWindow+Hooks.h"
#import "NSDOMNodeList+Hooks.h"
#import "SystemHelpers.h"
#import "Profiling.hpp"
#import "GeneralHelpers.h"
#import "Paths.h"

@interface Startup ()

@end

@implementation Startup

#pragma mark - Entry Point

+ (void)runStartupTasks {
    if (![Device isSimulator]) {
        [self rerouteNSLogToPersistentFile];
    }
    [self updateExternalKeepAliveStatus:NO];
    [self setUpLegacyGlobals];
}

#pragma mark - Logging

+ (void)rerouteNSLogToPersistentFile {
    int temporaryFileDescriptor;
    temporaryFileDescriptor = open("/tmp/cydia.log",
                                   O_WRONLY | O_APPEND | O_CREAT,
                                   0644);
    
    [self duplicateFileDescriptor:temporaryFileDescriptor
                newFileDescriptor:STDERR_FILENO];
    
    close(temporaryFileDescriptor);
}

+ (void)duplicateFileDescriptor:(int)fileDescriptor
              newFileDescriptor:(int)newFileDescriptor {
    dup2(fileDescriptor, newFileDescriptor);
}

#pragma mark - Status

static const char * CydiaNotifyName = "com.saurik.Cydia.status";

+ (void)updateExternalKeepAliveStatus:(BOOL)keepAlive {
    int notifyToken;
    
    uint64_t newStatus = keepAlive ? 1 : 0;
    
    if (notify_register_check(CydiaNotifyName, &notifyToken) == NOTIFY_STATUS_OK) {
        notify_set_state(notifyToken, newStatus);
        notify_cancel(notifyToken);
    }
    notify_post(CydiaNotifyName);
}

+ (void)setUpLegacyGlobals {
    UIDevice *device = [UIDevice currentDevice];
    RegEx pattern = "([0-9]+\\.[0-9]+).*";
    if (pattern([device systemVersion])) {
        Firmware_ = pattern[1];
    }
    
    if (pattern(Cydia_)) {
        Major_ = pattern[1];
    }
    
    SessionData_ = [NSMutableDictionary dictionaryWithCapacity:4];
    
    HostConfig_ = [[NSObject new] autorelease];
    @synchronized (HostConfig_) {
        BridgedHosts_ = [NSMutableSet setWithCapacity:4];
        InsecureHosts_ = [NSMutableSet setWithCapacity:4];
        PipelinedHosts_ = [NSMutableSet setWithCapacity:4];
        CachedURLs_ = [NSMutableSet setWithCapacity:32];
    }
    
    NSString *idiom = [Device isPad] ? @"ipad" : @"iphone";
    NSString *ui = @"ui/ios";
    ui = [ui stringByAppendingString:[NSString stringWithFormat:@"~%@", idiom]];
    ui = [ui stringByAppendingString:[NSString stringWithFormat:@"/%@", Major_]];
    UI_ = CydiaURL(ui);
    
    PackageName = reinterpret_cast<CYString &(*)(Package *, SEL)>(method_getImplementation(class_getInstanceMethod([Package class], @selector(cyname))));
    [self setUpLibraryHacks];
    [self setUpLocale];
    [self setUpIndexCollation];
    
    App_ = [NSBundle mainBundle].bundlePath;
    Advanced_ = TRUE;
    
    Cache_ = [[NSString stringWithFormat:@"%@/Library/Caches/com.saurik.Cydia", @"/var/mobile"] retain];
    
    if (![Device isSimulator]) {
        mkdir([Cache_ UTF8String], 0755);
    }
    
    void *gestalt(dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY));
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    
    [self setUpSystemInformation];
    [self setUpAPT];
    [self setUpDatabase];
    
    Finishes_ = @[@"return", @"reopen", @"restart", @"reload", @"reboot"];
    
    bool deviceIsiOS8OrHigher = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0;
    if (![Device isSimulator] && deviceIsiOS8OrHigher) {
        system("/usr/libexec/cydia/cydo /usr/libexec/cydia/setnsfpn /var/lib");
    }
    
    int version = [NSString stringWithContentsOfFile:@"/var/lib/cydia/firmware.ver"
                                            encoding:NSUTF8StringEncoding error:nil].intValue;
    
    if (![Device isSimulator]) {
        if (access("/User", F_OK) != 0 || version != 6) {
            _trace();
            system("/usr/libexec/cydia/cydo /usr/libexec/cydia/firmware.sh");
            _trace();
        }
    }
    
    if (![Device isSimulator]) {
        if (access("/tmp/cydia.chk", F_OK) == 0) {
            if (unlink([Cache("pkgcache.bin") UTF8String]) == -1)
                _assert(errno == ENOENT);
            if (unlink([Cache("srcpkgcache.bin") UTF8String]) == -1)
                _assert(errno == ENOENT);
        }
    }
    
    if (![Device isSimulator]) {
        system("/usr/libexec/cydia/cydo /bin/ln -sf /var/mobile/Library/Caches/com.saurik.Cydia/sources.list /etc/apt/sources.list.d/cydia.list");
    }
    
    [self setUpAPT];
    [self setUpTheme];
    NSLog(@"Finished running startup tasks");
}

+ (void)setUpLibraryHacks {
    [NSDOMNodeList_Hooks setUpHooks];
    [WAKWindow setUpHooks];
    [NSUserDefaults setUpHooks];
    [NSURLConnection setUpHooks];
}

+ (void)setUpLocale {
    Locale_ = CFLocaleCopyCurrent();
    Languages_ = [NSLocale preferredLanguages];
    
    //CFStringRef locale(CFLocaleGetIdentifier(Locale_));
    //NSLog(@"%@", [Languages_ description]);
    
    const char *lang;
    if (Locale_ != NULL)
        lang = [(NSString *) CFLocaleGetIdentifier(Locale_) UTF8String];
    else if (Languages_ != nil && [Languages_ count] != 0)
        lang = [[Languages_ objectAtIndex:0] UTF8String];
    else
        // XXX: consider just setting to C and then falling through?
        lang = NULL;
    
    if (lang != NULL) {
        RegEx pattern("([a-z][a-z])(?:-[A-Za-z]*)?(_[A-Z][A-Z])?");
        lang = !pattern(lang) ? NULL : [pattern->*@"%1$@%2$@" UTF8String];
    }
    
    NSLog(@"Setting Language: %s", lang);
    
    if (lang != NULL) {
        setenv("LANG", lang, true);
        std::setlocale(LC_ALL, lang);
    }
}

+ (void)setUpIndexCollation {
    if (Class $UILocalizedIndexedCollation = objc_getClass("UILocalizedIndexedCollation")) { @try {
        NSBundle *bundle([NSBundle bundleForClass:$UILocalizedIndexedCollation]);
        NSString *path([bundle pathForResource:@"UITableViewLocalizedSectionIndex" ofType:@"plist"]);
        //path = @"/System/Library/Frameworks/UIKit.framework/.lproj/UITableViewLocalizedSectionIndex.plist";
        NSDictionary *dictionary([NSDictionary dictionaryWithContentsOfFile:path]);
        _H<UILocalizedIndexedCollation> collation([[[$UILocalizedIndexedCollation alloc] initWithDictionary:dictionary] autorelease]);
        
        CollationLocale_ = MSHookIvar<NSLocale *>(collation, "_locale");
        
        if (kCFCoreFoundationVersionNumber >= 800 && [[CollationLocale_ localeIdentifier] isEqualToString:@"zh@collation=stroke"]) {
            CollationThumbs_ = [NSArray arrayWithObjects:@"1",@"•",@"4",@"•",@"7",@"•",@"10",@"•",@"13",@"•",@"16",@"•",@"19",@"A",@"•",@"E",@"•",@"I",@"•",@"M",@"•",@"R",@"•",@"V",@"•",@"Z",@"#",nil];
            for (NSInteger offset : (NSInteger[]) {0,1,3,4,6,7,9,10,12,13,15,16,18,25,26,29,30,33,34,37,38,42,43,46,47,50,51})
                CollationOffset_.push_back(offset);
            CollationTitles_ = [NSArray arrayWithObjects:@"1 畫",@"2 畫",@"3 畫",@"4 畫",@"5 畫",@"6 畫",@"7 畫",@"8 畫",@"9 畫",@"10 畫",@"11 畫",@"12 畫",@"13 畫",@"14 畫",@"15 畫",@"16 畫",@"17 畫",@"18 畫",@"19 畫",@"20 畫",@"21 畫",@"22 畫",@"23 畫",@"24 畫",@"25 畫以上",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
            CollationStarts_ = [NSArray arrayWithObjects:@"一",@"丁",@"丈",@"不",@"且",@"丞",@"串",@"並",@"亭",@"乘",@"乾",@"傀",@"亂",@"僎",@"僵",@"儐",@"償",@"叢",@"儳",@"嚴",@"儷",@"儻",@"囌",@"囑",@"廳",@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
        } else {
            
            CollationThumbs_ = [collation sectionIndexTitles];
            for (size_t index(0), end([CollationThumbs_ count]); index != end; ++index)
                CollationOffset_.push_back([collation sectionForSectionIndexTitleAtIndex:index]);
            
            CollationTitles_ = [collation sectionTitles];
            CollationStarts_ = MSHookIvar<NSArray *>(collation, "_sectionStartStrings");
            
            NSString *transform = MSHookIvar<NSString *>(collation, "_transform");
            if (transform != nil) {
                /*if ([collation respondsToSelector:@selector(transformedCollationStringForString:)])
                 CollationModify_ = [=](NSString *value) { return [collation transformedCollationStringForString:value]; };*/
                const UChar *uid(reinterpret_cast<const UChar *>([transform cStringUsingEncoding:NSUnicodeStringEncoding]));
                UErrorCode code(U_ZERO_ERROR);
                CollationTransl_ = utrans_openU(uid, -1, UTRANS_FORWARD, NULL, 0, NULL, &code);
                if (!U_SUCCESS(code))
                    NSLog(@"%s", u_errorName(code));
            }
            
        }
    } @catch (NSException *e) {
        NSLog(@"%@", e);
        goto hard;
    } } else hard: {
        CollationLocale_ = [[[NSLocale alloc] initWithLocaleIdentifier:@"en@collation=dictionary"] autorelease];
        
        CollationThumbs_ = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        for (NSInteger offset(0); offset != 28; ++offset)
            CollationOffset_.push_back(offset);
        
        CollationTitles_ = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",nil];
        CollationStarts_ = [NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z",@"ʒ",nil];
    }
}

+ (void)setUpSystemInformation {
    size_t size;
    
    int maxproc;
    size = sizeof(maxproc);
    if (sysctlbyname("kern.maxproc", &maxproc, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.maxproc\", ?)");
    else if (maxproc < 64) {
        maxproc = 64;
        if (sysctlbyname("kern.maxproc", NULL, NULL, &maxproc, sizeof(maxproc)) == -1)
            perror("sysctlbyname(\"kern.maxproc\", #)");
    }
    
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *osversion = new char[size];
    if (sysctlbyname("kern.osversion", osversion, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"kern.osversion\", ?)");
    else
        System_ = [NSString stringWithUTF8String:osversion];
    
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = new char[size];
    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == -1)
        perror("sysctlbyname(\"hw.machine\", ?)");
    else
        Machine_ = machine;
    
    int64_t usermem(0);
    size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1)
        usermem = 0;
    
    SerialNumber_ = (NSString *) CYIOGetValue("IOService:/", @"IOPlatformSerialNumber");
    ChipID_ = [CYHex((NSData *) CYIOGetValue("IODeviceTree:/chosen", @"unique-chip-id"), true) uppercaseString];
    BBSNum_ = CYHex((NSData *) CYIOGetValue("IOService:/AppleARMPE/baseband", @"snum"), false);
    
    UniqueID_ = UniqueIdentifier([UIDevice currentDevice]);
    
    if (NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:@"/Applications/MobileSafari.app/Info.plist"]) {
        Product_ = [info objectForKey:@"SafariProductVersion"];
        Safari_ = [info objectForKey:@"CFBundleVersion"];
    }
    
    NSString *agent([NSString stringWithFormat:@"Cydia/%@ CyF/%.2f", Cydia_, kCFCoreFoundationVersionNumber]);
    
    if (RegEx match = RegEx("([0-9]+(\\.[0-9]+)+).*", Safari_))
        agent = [NSString stringWithFormat:@"Safari/%@ %@", match[1], agent];
    if (RegEx match = RegEx("([0-9]+[A-Z][0-9]+[a-z]?).*", System_))
        agent = [NSString stringWithFormat:@"Mobile/%@ %@", match[1], agent];
    if (RegEx match = RegEx("([0-9]+(\\.[0-9]+)+).*", Product_))
        agent = [NSString stringWithFormat:@"Version/%@ %@", match[1], agent];
    
    UserAgent_ = agent;
}

+ (void)setUpDatabase {
    SectionMap_ = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sections" ofType:@"plist"]] autorelease];
    
    _trace();
    NSString *applicationLibraryDirectory = [Paths applicationLibraryDirectory];
    mkdir(applicationLibraryDirectory.UTF8String, 0755);
    NSString *metadataPath = [applicationLibraryDirectory
                              stringByAppendingPathComponent:@"metadata.cb0"];
    MetaFile_.Open(metadataPath.UTF8String);
    _trace();
    
    Values_ = [self autoreleasedDeepMutableDictionaryCopy:CFPreferencesCopyAppValue(CFSTR("CydiaValues"), CFSTR("com.saurik.Cydia")) ];
    Sections_ = [self autoreleasedDeepMutableDictionaryCopy:CFPreferencesCopyAppValue(CFSTR("CydiaSections"), CFSTR("com.saurik.Cydia"))];
    Sources_ = [self autoreleasedDeepMutableDictionaryCopy:CFPreferencesCopyAppValue(CFSTR("CydiaSources"), CFSTR("com.saurik.Cydia"))];
    Version_ = [(NSNumber *) CFPreferencesCopyAppValue(CFSTR("CydiaVersion"), CFSTR("com.saurik.Cydia")) autorelease];
    
    _trace();
    NSString *varLibCydiaDirectory = [Paths varLibCydiaDirectory];
    NSString *metaDataPlistPath = [varLibCydiaDirectory
                                   stringByAppendingPathComponent:@"metadata.plist"];
    NSDictionary *metadata = [[[NSMutableDictionary alloc]
                               initWithContentsOfFile:metaDataPlistPath]
                              autorelease];
    
    if (Values_ == nil)
        Values_ = [metadata objectForKey:@"Values"];
    if (Values_ == nil)
        Values_ = [[[NSMutableDictionary alloc] initWithCapacity:4] autorelease];
    
    if (Sections_ == nil)
        Sections_ = [metadata objectForKey:@"Sections"];
    if (Sections_ == nil)
        Sections_ = [[[NSMutableDictionary alloc] initWithCapacity:32] autorelease];
    
    if (Sources_ == nil)
        Sources_ = [metadata objectForKey:@"Sources"];
    if (Sources_ == nil)
        Sources_ = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
    
    // XXX: this wrong, but in a way that doesn't matter :/
    if (Version_ == nil)
        Version_ = [metadata objectForKey:@"Version"];
    if (Version_ == nil)
        Version_ = [NSNumber numberWithUnsignedInt:0];
    
    if (NSDictionary *packages = [metadata objectForKey:@"Packages"]) {
        bool fail(false);
        CFDictionaryApplyFunction((CFDictionaryRef) packages, &PackageImport, &fail);
        _trace();
        if (fail)
            NSLog(@"unable to import package preferences... from 2010? oh well :/");
    }
    
    if ([Version_ unsignedIntValue] == 0) {
        CydiaAddSource(@"http://apt.thebigboss.org/repofiles/cydia/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://apt.modmyi.com/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://cydia.zodttd.com/repo/cydia/", @"stable", [NSMutableArray arrayWithObject:@"main"]);
        CydiaAddSource(@"http://repo666.ultrasn0w.com/", @"./");
        
        Version_ = [NSNumber numberWithUnsignedInt:1];
        
        if (NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:[Paths cacheState]]) {
            [cache removeObjectForKey:@"LastUpdate"];
            [cache writeToFile:[Paths cacheState] atomically:YES];
        }
    }
    
    _H<NSMutableArray> broken([NSMutableArray array]);
    for (NSString *key in (id) Sources_)
        if ([key rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"# "]].location != NSNotFound || ![([[Sources_ objectForKey:key] objectForKey:@"URI"] ?: @"/") hasSuffix:@"/"])
            [broken addObject:key];
    if ([broken count] != 0)
        for (NSString *key in (id) broken)
            [Sources_ removeObjectForKey:key];
    broken = nil;
    
    SaveConfig(nil);
    if (![Device isSimulator]) {
        system("/usr/libexec/cydia/cydo /bin/rm -f /var/lib/cydia/metadata.plist");
    }
    
    $SBSSetInterceptsMenuButtonForever = reinterpret_cast<void (*)(bool)>(dlsym(RTLD_DEFAULT, "SBSSetInterceptsMenuButtonForever"));
    $SBSCopyIconImagePNGDataForDisplayIdentifier = reinterpret_cast<NSData *(*)(NSString *)>(dlsym(RTLD_DEFAULT, "SBSCopyIconImagePNGDataForDisplayIdentifier"));
    
    const char *symbol(kCFCoreFoundationVersionNumber >= 800 ? "MGGetBoolAnswer" : "GSSystemHasCapability");
    BOOL (*GSSystemHasCapability)(CFStringRef) = reinterpret_cast<BOOL (*)(CFStringRef)>(dlsym(RTLD_DEFAULT, symbol));
    bool fast = GSSystemHasCapability != NULL && GSSystemHasCapability(CFSTR("armv7"));
    
    PulseInterval_ = fast ? 50000 : 500000;
    
    Colon_ = UCLocalize("COLON_DELIMITED");
    Elision_ = UCLocalize("ELISION");
    Error_ = UCLocalize("ERROR");
    Warning_ = UCLocalize("WARNING");
    
    _trace();
}

+ (void)setUpAPT {
    _assert(pkgInitConfig(*_config));
    _config->Set("Apt::System", "Debian dpkg interface");
    bool ret = pkgInitSystem(*_config, _system);
    
    if (!ret) {
        GlobalError *error = _GetErrorObj();
        std::string errorMessage;
        error->PopMessage(errorMessage);
        std::cout << "Error: " << errorMessage << std::endl;
    }
    _assert(ret);
    
    
    const char *lang = getenv("LANG");
    if (lang != NULL) {
        _config->Set("APT::Acquire::Translation", lang);
    }
    
    int64_t usermem(0);
    size_t size = sizeof(usermem);
    if (sysctlbyname("hw.usermem", &usermem, &size, NULL, 0) == -1) {
        usermem = 0;
    }
    _config->Set("Acquire::http::MaxParallel", usermem >= 384 * 1024 * 1024 ? 16 : 3);
    
    mkdir([Cache("archives") UTF8String], 0755);
    mkdir([Cache("archives/partial") UTF8String], 0755);
    _config->Set("Dir::Cache", [Cache_ UTF8String]);
    
    symlink("/var/lib/apt/extended_states", [Cache("extended_states") UTF8String]);
    _config->Set("Dir::State", [Cache_ UTF8String]);
    
    mkdir([Cache("lists") UTF8String], 0755);
    mkdir([Cache("lists/partial") UTF8String], 0755);
    mkdir([Cache("periodic") UTF8String], 0755);
    _config->Set("Dir::State::Lists", [Cache("lists") UTF8String]);
    
    std::string logs("/var/mobile/Library/Logs/Cydia");
    mkdir(logs.c_str(), 0755);
    _config->Set("Dir::Log::Terminal", logs + "/apt.log");
    
    _config->Set("Dir::Bin::dpkg", "/usr/libexec/cydia/cydo");
}

+ (void)setUpTheme {
    space_ = CGColorSpaceCreateDeviceRGB();
    
    Blue_.Set(space_, 0.2, 0.2, 1.0, 1.0);
    Blueish_.Set(space_, 0x19/255.f, 0x32/255.f, 0x50/255.f, 1.0);
    Black_.Set(space_, 0.0, 0.0, 0.0, 1.0);
    Folder_.Set(space_, 0x8e/255.f, 0x8e/255.f, 0x93/255.f, 1.0);
    Off_.Set(space_, 0.9, 0.9, 0.9, 1.0);
    White_.Set(space_, 1.0, 1.0, 1.0, 1.0);
    Gray_.Set(space_, 0.4, 0.4, 0.4, 1.0);
    Green_.Set(space_, 0.0, 0.5, 0.0, 1.0);
    Purple_.Set(space_, 0.0, 0.0, 0.7, 1.0);
    Purplish_.Set(space_, 0.4, 0.4, 0.8, 1.0);
    
    InstallingColor_ = [UIColor colorWithRed:0.88f green:1.00f blue:0.88f alpha:1.00f];
    RemovingColor_ = [UIColor colorWithRed:1.00f green:0.88f blue:0.88f alpha:1.00f];
}

#pragma mark - Copying

+ (NSMutableDictionary *)autoreleasedDeepMutableDictionaryCopy:(CFTypeRef)type {
    if (type == NULL)
        return nil;
    if (CFGetTypeID(type) != CFDictionaryGetTypeID())
        return nil;
    CFTypeRef copy(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, type, kCFPropertyListMutableContainers));
    CFRelease(type);
    return [(NSMutableDictionary *) copy autorelease];
}

@end
