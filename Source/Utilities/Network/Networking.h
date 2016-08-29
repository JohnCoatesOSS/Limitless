//
//  Networking.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Menes/Menes.h"
#import "CyteKit.h"
#import "UIGlobals.h"

// Globals

extern _H<NSMutableDictionary> Sources_;

static _H<NSMutableDictionary> SessionData_;
static _H<NSObject> HostConfig_;
static _H<NSMutableSet> BridgedHosts_;
static _H<NSMutableSet> InsecureHosts_;
static _H<NSMutableSet> PipelinedHosts_;
static _H<NSMutableSet> CachedURLs_;


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

inline NSString *VerifySource(NSString *href) {
    static RegEx href_r("(http(s?)://|file:///)[^# ]*");
    if (!href_r(href)) {
        [[[[UIAlertView alloc]
           initWithTitle:[NSString stringWithFormat:Colon_, Error_, UCLocalize("INVALID_URL")]
           message:UCLocalize("INVALID_URL_EX")
           delegate:nil
           cancelButtonTitle:UCLocalize("OK")
           otherButtonTitles:nil
           ] autorelease] show];
        
        return nil;
    }
    
    if (![href hasSuffix:@"/"])
        href = [href stringByAppendingString:@"/"];
    return href;
}