//
//  CYString.hpp
//  Cydia
//
//  Created on 8/29/16.
//

#import "CyteKit.h"
#import "Menes/Menes.h"
#import "Standard.h"

// C++ NSString Wrapper Cache

static _finline CFStringRef CYStringCreate(const char *data, size_t size) {
    return size == 0 ? NULL :
    CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, reinterpret_cast<const uint8_t *>(data), size, kCFStringEncodingUTF8, NO, kCFAllocatorNull) ?:
    CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, reinterpret_cast<const uint8_t *>(data), size, kCFStringEncodingISOLatin1, NO, kCFAllocatorNull);
}

static _finline CFStringRef CYStringCreate(const char *data) {
    return CYStringCreate(data, strlen(data));
}

class CYString {
private:
    char *data_;
    size_t size_;
    CFStringRef cache_;
    
    _finline void clear_() {
        if (cache_ != NULL) {
            CFRelease(cache_);
            cache_ = NULL;
        }
    }
    
public:
    _finline bool empty() const {
        return size_ == 0;
    }
    
    _finline size_t size() const {
        return size_;
    }
    
    _finline char *data() const {
        return data_;
    }
    
    _finline void clear() {
        size_ = 0;
        clear_();
    }
    
    _finline CYString() :
    data_(0),
    size_(0),
    cache_(NULL)
    {
    }
    
    _finline ~CYString() {
        clear_();
    }
    
    void operator =(const CYString &rhs) {
        data_ = rhs.data_;
        size_ = rhs.size_;
        
        if (rhs.cache_ == nil)
            cache_ = NULL;
        else
            cache_ = reinterpret_cast<CFStringRef>(CFRetain(rhs.cache_));
    }
    
    void copy(CYPool *pool) {
        char *temp(pool->malloc<char>(size_ + 1));
        memcpy(temp, data_, size_);
        temp[size_] = '\0';
        data_ = temp;
    }
    
    void set(CYPool *pool, const char *data, size_t size) {
        if (size == 0)
            clear();
        else {
            clear_();
            
            data_ = const_cast<char *>(data);
            size_ = size;
            
            if (pool != NULL)
                copy(pool);
        }
    }
    
    _finline void set(CYPool *pool, const char *data) {
        set(pool, data, data == NULL ? 0 : strlen(data));
    }
    
    _finline void set(CYPool *pool, const std::string &rhs) {
        set(pool, rhs.data(), rhs.size());
    }
    
    bool operator ==(const CYString &rhs) const {
        return size_ == rhs.size_ && memcmp(data_, rhs.data_, size_) == 0;
    }
    
    _finline operator CFStringRef() {
        if (cache_ == NULL)
            cache_ = CYStringCreate(data_, size_);
        return cache_;
    }
    
    #if !__has_feature(objc_arc)
    _finline operator id() {
        return (NSString *) static_cast<CFStringRef>(*this);
    }
    #endif
    
    _finline operator const char *() {
        return reinterpret_cast<const char *>(data_);
    }
};
