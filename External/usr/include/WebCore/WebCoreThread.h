/*
 *  WebCoreThread.h
 *  WebCore
 *
 *  Copyright (C) 2006, 2007, 2008, 2009 Apple Inc.  All rights reserved.
 */

#ifndef WebCoreThread_h
#define WebCoreThread_h

#import <CoreGraphics/CoreGraphics.h>

#if defined(__cplusplus)
extern "C" {
#endif    
        
typedef struct {
    CGContextRef currentCGContext;
} WebThreadContext;
    
extern bool webThreadShouldYield;

// The lock is automatically freed at the bottom of the runloop. No need to unlock.
// Note that calling this function may hang your UI for several seconds. Don't use
// unless you have to.
void WebThreadLock(void);
    
// This is a no-op for compatibility only. It will go away. Please don't use.
void WebThreadUnlock(void);
    
// Please don't use anything below this line unless you know what you are doing. If unsure, ask.
// ---------------------------------------------------------------------------------------------
bool WebTryThreadLock(void);
bool WebThreadIsLocked(void);
bool WebThreadIsLockedOrDisabled(void);
    
void WebThreadLockPushModal(void);
void WebThreadLockPopModal(void);

void WebThreadEnable(void);
bool WebThreadIsEnabled(void);
bool WebThreadIsCurrent(void);
bool WebThreadNotCurrent(void);
    
// These are for <rdar://problem/6817341> Many apps crashing calling -[UIFieldEditor text] in secondary thread
// Don't use them to solve any random problems you might have.
void WebThreadLockFromAnyThread();
void WebThreadUnlockFromAnyThread();

static inline bool WebThreadShouldYield(void) { return webThreadShouldYield; }
static inline void WebThreadSetShouldYield() { webThreadShouldYield = true; }

CFRunLoopRef WebThreadRunLoop(void);
WebThreadContext *WebThreadCurrentContext(void);
bool WebThreadContextIsCurrent(void);

void WebThreadPrepareForDrawing(void);

#if defined(__cplusplus)
}
#endif

#endif // WebCoreThread_h
