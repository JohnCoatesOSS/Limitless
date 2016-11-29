//
//  Startup.h
//  Cydia
//
//  Created on 8/31/16.
//

@interface Startup : NSObject

// Startup
+ (void)runStartupTasks;

// Status
+ (void)updateExternalKeepAliveStatus:(BOOL)keepAlive;

@end
