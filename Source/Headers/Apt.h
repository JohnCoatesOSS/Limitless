//
//  Apt.h
//  Cydia
//
//  Created on 8/29/16.
//

#undef ABS

#define APT_DEPRECATED __attribute__((deprecated("Use a wrapper instead of this APT class")))

#define APT_SILENCE_DEPRECATIONS \
_Pragma ("GCC diagnostic push") \
_Pragma ("GCC diagnostic ignored \"-Wdeprecated-declarations\"")

#define APT_UNSILENCE_DEPRECATIONS \
_Pragma ("GCC diagnostic pop")

APT_SILENCE_DEPRECATIONS

#include <apt-pkg/acquire.h>
#include <apt-pkg/acquire-item.h>
#include <apt-pkg/algorithms.h>
#include <apt-pkg/cachefile.h>
#include <apt-pkg/clean.h>
#include <apt-pkg/configuration.h>
#include <apt-pkg/debindexfile.h>
#include <apt-pkg/debmetaindex.h>
#include <apt-pkg/error.h>
#include <apt-pkg/init.h>
#include <apt-pkg/mmap.h>
#include <apt-pkg/pkgrecords.h>
#include <apt-pkg/sha1.h>
#include <apt-pkg/sourcelist.h>
#include <apt-pkg/sptr.h>
#include <apt-pkg/strutl.h>
#include <apt-pkg/tagfile.h>

APT_UNSILENCE_DEPRECATIONS

// MARK: - Wrappers

#import "APTDependencyCachePolicy.h"
