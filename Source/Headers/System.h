//
//  System.h
//  Cydia
//
//  Created on 8/30/16.
//
// Include this first or you might get the error "functions that differ only in their return type cannot be overloaded"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/reboot.h>

#include <dirent.h>
#include <fcntl.h>
#include <notify.h>
#include <dlfcn.h>

#include <objc/objc.h>
#include <objc/runtime.h>