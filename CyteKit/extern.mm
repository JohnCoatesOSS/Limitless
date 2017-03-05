/* Cydia - iPhone UIKit Front-End for Debian APT
 * Copyright (C) 2008-2015  Jay Freeman (saurik)
*/

/* GNU General Public License, Version 3 {{{ */
/*
 * Cydia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Cydia is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cydia.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

#include <CyteKit/extern.h>

#include <SystemConfiguration/SystemConfiguration.h>
#include <UIKit/UIKit.h>

bool IsWildcat_;
CGFloat ScreenScale_;

bool CyteIsReachable(const char *name) {
    SCNetworkReachabilityFlags flags; {
        SCNetworkReachabilityRef reachability(SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, name));
        SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
    }

    // XXX: this elaborate mess is what Apple is using to determine this? :(
    // XXX: do we care if the user has to intervene? maybe that's ok?
    return
        (flags & kSCNetworkReachabilityFlagsReachable) != 0 && (
            (flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0 || (
                (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 ||
                (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0
            ) && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0 ||
            (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0
        )
    ;
}

__attribute__((__constructor__))
void CyteKit_extern() {
    UIScreen *screen([UIScreen mainScreen]);
    if ([screen respondsToSelector:@selector(scale)])
        ScreenScale_ = [screen scale];
    else
        ScreenScale_ = 1;

    UIDevice *device([UIDevice currentDevice]);
    if ([device respondsToSelector:@selector(userInterfaceIdiom)]) {
        UIUserInterfaceIdiom idiom([device userInterfaceIdiom]);
        if (idiom == UIUserInterfaceIdiomPad)
            IsWildcat_ = true;
    }
}
