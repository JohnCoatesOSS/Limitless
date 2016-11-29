//
//  GeneralGlobals.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "GeneralGlobals.h"

NSString *Cache_;
int PulseInterval_ = 500000;

int Finish_;
bool RestartSubstrate_;
NSArray *Finishes_;

#define SpringBoard_ "/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
#define NotifyConfig_ "/etc/notify.conf"

bool Queuing_;

NSString *App_;

BOOL Advanced_;
BOOL Ignored_;

NSNumber *Version_;
time_t now_;

NSString *kCydiaProgressEventTypeError = @"Error";
NSString *kCydiaProgressEventTypeInformation = @"Information";
NSString *kCydiaProgressEventTypeStatus = @"Status";
NSString *kCydiaProgressEventTypeWarning = @"Warning";

_H<NSMutableDictionary> Sources_;