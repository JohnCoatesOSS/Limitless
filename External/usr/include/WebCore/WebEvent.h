/*
 * Copyright (C) 2009, Apple Inc. All rights reserved.
 *
 */

#ifndef WebEvent_h
#define WebEvent_h

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

typedef enum {
    WebEventMouseDown,
    WebEventMouseUp,
    WebEventMouseMoved,
    
    WebEventScrollWheel,
    
    WebEventKeyDown,
    WebEventKeyUp,
    
    WebEventTouchBegin,
    WebEventTouchChange,
    WebEventTouchEnd,
    WebEventTouchCancel
} WebEventType;

// These enum values are copied directly from GSEvent for compatibility.
typedef enum
{
    WebEventFlagMaskAlphaShift = 0x00010000,
    WebEventFlagMaskShift      = 0x00020000,
    WebEventFlagMaskControl    = 0x00040000,
    WebEventFlagMaskAlternate  = 0x00080000,
    WebEventFlagMaskCommand    = 0x00100000,
} WebEventFlags;

// These enum values are copied directly from GSEvent for compatibility.
typedef enum
{
    WebEventCharacterSetASCII           = 0,
    WebEventCharacterSetSymbol          = 1,
    WebEventCharacterSetDingbats        = 2,
    WebEventCharacterSetUnicode         = 253,
    WebEventCharacterSetFunctionKeys    = 254,
} WebEventCharacterSet;

@interface WebEvent : NSObject {
@private
    WebEventType _type;
    CFTimeInterval _timestamp;
    
    CGPoint _locationInWindow;
    
    NSString *_characters;
    NSString *_charactersIgnoringModifiers;
    WebEventFlags _modifierFlags;
    BOOL _keyRepeating;
    uint16_t _keyCode;
    BOOL _tabKey;
    WebEventCharacterSet _characterSet;
    
    float _deltaX;
    float _deltaY;
    
    unsigned _touchCount;
    NSArray *_touchLocations;
    NSArray *_touchGlobalLocations;
    NSArray *_touchIdentifiers;
    
    BOOL _gestureChanged;
    float _gestureScale;
    float _gestureRotation;
}

- (WebEvent *)initWithMouseEventType:(WebEventType)type withTimeStamp:(CFTimeInterval)timeStamp withLocation:(CGPoint)point;
- (WebEvent *)initWithScrollWheelEventWithTimeStamp:(CFTimeInterval)timeStamp withLocation:(CGPoint)point withDeltaX:(float)deltaX withDeltaY:(float)deltaY;
- (WebEvent *)initWithTouchEventType:(WebEventType)type withTimeStamp:(CFTimeInterval)timeStamp withLocation:(CGPoint)point withTouchCount:(unsigned)touchCount withTouchLocations:(NSArray *)touchLocations withTouchGlobalLocations:(NSArray *)touchGlobalLocations withTouchIdentifiers:(NSArray *)touchIdentifiers withGestureChanged:(BOOL)gestureChanged withGestureScale:(float)gestureScale withGestureRotation:(float)gestureRotation;
- (WebEvent *)initWithKeyEventType:(WebEventType)type withTimeStamp:(CFTimeInterval)timeStamp withCharacters:(NSString *)characters withCharactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers withModifiers:(WebEventFlags)modifiers isRepeating:(BOOL)repeating withKeyCode:(uint16_t)keyCode isTabKey:(BOOL)tabKey withCharacterSet:(WebEventCharacterSet)characterSet;

@property(nonatomic,readonly) WebEventType type;
@property(nonatomic,readonly) CFTimeInterval timestamp;

// Mouse
@property(nonatomic,readonly) CGPoint locationInWindow;

// Keyboard
@property(nonatomic,readonly,retain) NSString *characters;
@property(nonatomic,readonly,retain) NSString *charactersIgnoringModifiers;
@property(nonatomic,readonly) WebEventFlags modifierFlags;
@property(nonatomic,readonly,getter=isKeyRepeating) BOOL keyRepeating;
@property(nonatomic,readonly) uint16_t keyCode;
@property(nonatomic,readonly,getter=isTabKey) BOOL tabKey;
@property(nonatomic,readonly) WebEventCharacterSet characterSet;

// Scroll Wheel
@property(nonatomic,readonly) float deltaX;
@property(nonatomic,readonly) float deltaY;

// Touch
@property(nonatomic,readonly) unsigned touchCount;
@property(nonatomic,readonly,retain) NSArray *touchLocations;
@property(nonatomic,readonly,retain) NSArray *touchGlobalLocations;
@property(nonatomic,readonly,retain) NSArray *touchIdentifiers;

// Gesture
@property(nonatomic,readonly) BOOL gestureChanged;
@property(nonatomic,readonly) float gestureScale;
@property(nonatomic,readonly) float gestureRotation;
@end

#endif // WebEvent_h
