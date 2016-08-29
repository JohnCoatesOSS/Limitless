//
//  Profiling.h
//  Cydia
//
//  Created on 8/29/16.
//
#include <algorithm>
#include <iomanip>
#include <set>
#include <sstream>
#include <string>

#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <errno.h>
#include <iostream>
#include <sys/time.h>

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
    
    void Print();
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

void PrintTimes();

#define _profile(name) { \
static ProfileTime name(#name); \
ProfileTimer _ ## name(name);

#define _end }