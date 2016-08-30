//
//  CydiaProgressData.h
//  Cydia
//
//  Created on 8/30/16.
//

#import "Menes/Menes.h"

@class CydiaProgressEvent;

@interface CydiaProgressData : NSObject {
    _transient id delegate_;
    
    bool running_;
    float percent_;
    
    float current_;
    float total_;
    float speed_;
    
    _H<NSMutableArray> events_;
    _H<NSString> title_;
    
    _H<NSString> status_;
    _H<NSString> finish_;
}

+ (NSArray *) _attributeKeys;
- (NSArray *) attributeKeys;
- (id) init;
- (id) delegate;
- (void) setDelegate:(id)delegate;
- (void) setPercent:(float)value;
- (NSNumber *) percent;
- (void) setCurrent:(float)value;
- (NSNumber *) current;
- (void) setTotal:(float)value;
- (NSNumber *) total;
- (void) setSpeed:(float)value;
- (NSNumber *) speed;
- (NSArray *) events;
- (void) removeAllEvents;
- (void) addEvent:(CydiaProgressEvent *)event;
- (void) setTitle:(NSString *)text;
- (NSString *) title;
- (void) setFinish:(NSString *)text;
- (NSString *) finish;
- (void) setRunning:(bool)running;
- (NSNumber *) running;

@end