//
//  Networking.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"
#import "UIGlobals.h"
#import "NSURL+Cydia.h"

// Globals

extern _H<NSMutableDictionary> SessionData_;
extern _H<NSObject> HostConfig_;
extern _H<NSMutableSet> BridgedHosts_;
extern _H<NSMutableSet> InsecureHosts_;
extern _H<NSMutableSet> CachedURLs_;

/// Whether we have network connectivity to reach a domain
bool IsReachable(const char *name);

static _finline NSString *CydiaURL(NSString *path) {
    char page[26];
    page[0] = 'h'; page[1] = 't'; page[2] = 't'; page[3] = 'p'; page[4] = 's';
    page[5] = ':'; page[6] = '/'; page[7] = '/'; page[8] = 'c'; page[9] = 'y';
    page[10] = 'd'; page[11] = 'i'; page[12] = 'a'; page[13] = '.'; page[14] = 's';
    page[15] = 'a'; page[16] = 'u'; page[17] = 'r'; page[18] = 'i'; page[19] = 'k';
    page[20] = '.'; page[21] = 'c'; page[22] = 'o'; page[23] = 'm'; page[24] = '/';
    page[25] = '\0';
    return [[NSString stringWithUTF8String:page] stringByAppendingString:path];
}

NSString *VerifySource(NSString *href);
