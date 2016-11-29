//
//  Defines.h
//  Cydia
//
//  Created on 8/30/16.
//

// XXX: I hate clang. Apple: please get over your petty hatred of GPL and fix your gcc fork
#define synchronized(lock) \
synchronized(static_cast<NSObject *>(lock))

#define lprintf(args...) fprintf(stderr, args)

#define Cache(file) \
[NSString stringWithFormat:@"%@/%s", Cache_, file]