//
//  Apt.h
//  Cydia
//
//  Created on 8/29/16.
//

#undef ABS

#define APT_DEPRECATED __attribute__((deprecated("Use a wrapper instead of this APT class")))

#define APT_SILENCE_DEPRECATIONS_BEGIN \
_Pragma ("GCC diagnostic push") \
_Pragma ("GCC diagnostic ignored \"-Wdeprecated-declarations\"")

#define APT_SILENCE_DEPRECATIONS_END \
_Pragma ("GCC diagnostic pop")


APT_SILENCE_DEPRECATIONS_BEGIN

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

APT_SILENCE_DEPRECATIONS_END

// MARK: - Wrappers

#import "APTDependencyCachePolicy.h"
#import "APTError.h"
#import "APTErrorController.h"
#import "APTCacheFile.h"
#import "APTPackageProblemResolver.h"
#import "APTPackage.h"
#import "APTDownloadScheduler.h"
#import "APTRecords.h"

// MARK: - Controllers

#import "APTManager.h"
