//
//  Startup.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Startup : NSObject

// Startup
+ (void)runStartupTasks;

// Logging
+ (int)persistentLogFileDescriptor;
+ (void)openPersistentLogFile;

// Status
+ (void)updateExternalKeepAliveStatus:(BOOL)keepAlive;

@end
