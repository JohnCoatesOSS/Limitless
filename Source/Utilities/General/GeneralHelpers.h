//
//  GeneralHelpers.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Paths.h"
#import "Menes/Menes.h"
#import <notify.h>

// Hash Functions/Structures
extern "C" uint32_t hashlittle(const void *key, size_t length, uint32_t initval = 0);

union SplitHash {
    uint32_t u32;
    uint16_t u16[2];
};

static void (*$SBSSetInterceptsMenuButtonForever)(bool);
static NSData *(*$SBSCopyIconImagePNGDataForDisplayIdentifier)(NSString *);

static inline NSString *ShellEscape(NSString *value) {
    return [NSString stringWithFormat:@"'%@'", [value stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
}

static _finline void UpdateExternalStatus(uint64_t newStatus) {
    int notify_token;
    if (notify_register_check("com.saurik.Cydia.status", &notify_token) == NOTIFY_STATUS_OK) {
        notify_set_state(notify_token, newStatus);
        notify_cancel(notify_token);
    }
    notify_post("com.saurik.Cydia.status");
}

static inline NSDate *GetStatusDate() {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:[Paths dpkgStatus]
                                                             error:NULL] fileModificationDate];
}


