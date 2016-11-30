//
//  CYColor.hpp
//  Cydia
//
//  Created on 8/29/16.
//

#import <CoreGraphics/CoreGraphics.h>

// CoreGraphics Primitives

class CYColor {
private:
    
    static CGColorRef Create_(CGColorSpaceRef space, float red, float green, float blue, float alpha) {
        CGFloat color[] = {red, green, blue, alpha};
        return CGColorCreate(space, color);
    }
    
public:
	CGColorRef color_;
	
    CYColor() :
    color_(NULL)
    {
    }
    
    CYColor(CGColorSpaceRef space, float red, float green, float blue, float alpha) :
    color_(Create_(space, red, green, blue, alpha))
    {
        Set(space, red, green, blue, alpha);
    }
    
    void Clear() {
        if (color_ != NULL)
            CGColorRelease(color_);
    }
    
    ~CYColor() {
        Clear();
    }
    
    void Set(CGColorSpaceRef space, float red, float green, float blue, float alpha) {
        Clear();
        color_ = Create_(space, red, green, blue, alpha);
    }
    
    operator CGColorRef() {
        return color_;
    }
};
