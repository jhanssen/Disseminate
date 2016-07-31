#ifndef COCOAUTILS_H
#define COCOAUTILS_H

#import <Cocoa/Cocoa.h>

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

#endif
