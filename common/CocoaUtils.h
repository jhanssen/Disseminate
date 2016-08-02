#ifndef COCOAUTILS_H
#define COCOAUTILS_H

#import <Cocoa/Cocoa.h>
#include <mach/mach_time.h>
#include <string>

// From
// http://stackoverflow.com/questions/1597383/cgeventtimestamp-to-nsdate
// Which credits Apple sample code for this routine.
static inline uint64_t timeInNanoseconds(void)
{
    uint64_t time;
    uint64_t timeNano;
    static mach_timebase_info_data_t sTimebaseInfo;

    time = mach_absolute_time();

    // Convert to nanoseconds.

    // If this is the first time we've run, get the timebase.
    // We can use denom == 0 to indicate that sTimebaseInfo is
    // uninitialised because it makes no sense to have a zero
    // denominator is a fraction.
    if (sTimebaseInfo.denom == 0) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }

    // This could overflow; for testing needs we probably don't care.
    timeNano = time * sTimebaseInfo.numer / sTimebaseInfo.denom;
    return timeNano;
}

static inline NSTimeInterval timeIntervalSinceSystemStartup()
{
    return timeInNanoseconds() / 1000000000.0;
}

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

static inline std::string toStdString(NSString* str)
{
    return std::string([str UTF8String]);
}

struct NSStringWrapper
{
    enum Mode { Retain, NoRetain };
    NSStringWrapper(NSString* str, Mode mode = NoRetain)
        : s(str)
    {
        if (mode == Retain)
            [s retain];
    }
    ~NSStringWrapper()
    {
        [s release];
    }
    NSString* str() { return s; }

private:
    NSString* s;
};

static inline std::shared_ptr<NSStringWrapper> fromStdString(const std::string& str)
{
    NSString* nsstr = [[NSString alloc] initWithUTF8String:str.c_str()];
    return std::make_shared<NSStringWrapper>(nsstr);
}

#endif
