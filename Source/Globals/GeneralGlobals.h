//
//  GeneralGlobals.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Menes/Menes.h"

extern NSString *Cydia_;

static NSString *Cache_;
static int PulseInterval_ = 500000;

static int Finish_;
static bool RestartSubstrate_;
static NSArray *Finishes_;

#define SpringBoard_ "/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
#define NotifyConfig_ "/etc/notify.conf"

static bool Queuing_;

static NSString *App_;

static BOOL Advanced_;
static BOOL Ignored_;

#define CacheState_ "/var/mobile/Library/Caches/com.saurik.Cydia/CacheState.plist"
#define SavedState_ "/var/mobile/Library/Caches/com.saurik.Cydia/SavedState.plist"

static _transient NSNumber *Version_;
static time_t now_;

static NSString *kCydiaProgressEventTypeError = @"Error";
static NSString *kCydiaProgressEventTypeInformation = @"Information";
static NSString *kCydiaProgressEventTypeStatus = @"Status";
static NSString *kCydiaProgressEventTypeWarning = @"Warning";

extern _H<NSMutableDictionary> Sources_;