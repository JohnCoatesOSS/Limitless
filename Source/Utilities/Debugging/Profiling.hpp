//
//  Profiling.h
//  Cydia
//
//  Created on 8/29/16.
//

#import "Standard.h"
#import "Flags.h"

extern struct timeval _ltv;
extern bool _itv;

#define _timestamp ({ \
struct timeval tv; \
gettimeofday(&tv, NULL); \
tv.tv_sec * 1000000 + tv.tv_usec; \
})

typedef std::vector<class ProfileTime *> TimeList;
extern TimeList times_;

class ProfileTime {
private:
    const char *name_;
    uint64_t total_;
    uint64_t count_;
    
public:
    ProfileTime(const char *name) :
    name_(name),
    total_(0)
    {
        times_.push_back(this);
    }
    
    void AddTime(uint64_t time);
    
    void Print() {
        if (total_ != 0)
            std::cerr << std::setw(7) << count_ << ", " << std::setw(8) << total_ << " : " << name_ << std::endl;
        total_ = 0;
        count_ = 0;
    }
};

class ProfileTimer {
private:
    ProfileTime &time_;
    uint64_t start_;
    
public:
    ProfileTimer(ProfileTime &time) :
    time_(time),
    start_(_timestamp)
    {
    }
    
    ~ProfileTimer() {
        time_.AddTime(_timestamp - start_);
    }
};

inline void PrintTimes() {
    for (TimeList::const_iterator i(times_.begin()); i != times_.end(); ++i)
        (*i)->Print();
    std::cerr << "========" << std::endl;
}


#define _profile(name) { \
static ProfileTime name(#name); \
ProfileTimer _ ## name(name);

#define _end }

#if !TraceLogging
#undef _trace
#define _trace(args...)
#endif

#if !ProfileTimes
#undef _profile
#define _profile(name) {
#undef _end
#define _end }
#define PrintTimes() do {} while (false)
#endif