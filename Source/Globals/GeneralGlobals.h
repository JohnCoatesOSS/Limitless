//
//  GeneralGlobals.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Menes/Menes.h"

extern NSString *Cydia_;

extern NSString *Cache_;
extern int PulseInterval_;

extern int Finish_;
extern bool RestartSubstrate_;
extern NSArray *Finishes_;

#define SpringBoard_ "/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
#define NotifyConfig_ "/etc/notify.conf"

extern bool Queuing_;

extern NSString *App_;

extern BOOL Advanced_;
extern BOOL Ignored_;

extern NSNumber *Version_;
extern time_t now_;

extern NSString *kCydiaProgressEventTypeError;
extern NSString *kCydiaProgressEventTypeInformation;
extern NSString *kCydiaProgressEventTypeStatus;
extern NSString *kCydiaProgressEventTypeWarning;

extern _H<NSMutableDictionary> Sources_;