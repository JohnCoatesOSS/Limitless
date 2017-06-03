/* Cydia - iPhone UIKit Front-End for Debian APT
 * Copyright (C) 2008-2013  Jay Freeman (saurik)
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

#include <Foundation/Foundation.h>
#include <Menes/ObjectHandle.h>
#include <CyteKit/UCPlatform.h>

#include <cstdio>

#include "Sources.h"
#import "Paths.h"
#import "GeneralGlobals.h"

void CydiaWriteSources() {
    NSString *sourcesDirectory;
    NSString *sourcesListPath;
    if ([Platform isSandboxed]) {
        sourcesDirectory = Paths.aptEtcSourceParts;
    } else {
        sourcesDirectory = Paths.aptState;
    }
    sourcesListPath = [sourcesDirectory subpath:@"sources.list"];
    const char *sourcesListPathCString = sourcesListPath.UTF8String;
    unlink(sourcesListPathCString);
    FILE *file(fopen(sourcesListPathCString, "w"));
    _assert(file != NULL);

    fprintf(file, "deb http://apt.saurik.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber);

    for (NSString *key in [Sources_ allKeys]) {
        NSDictionary *source([Sources_ objectForKey:key]);

        NSArray *sections([source objectForKey:@"Sections"] ?: [NSArray array]);

        fprintf(file, "%s %s %s%s%s\n",
            [[source objectForKey:@"Type"] UTF8String],
            [[source objectForKey:@"URI"] UTF8String],
            [[source objectForKey:@"Distribution"] UTF8String],
            [sections count] == 0 ? "" : " ",
            [[sections componentsJoinedByString:@" "] UTF8String]
        );
    }

    fclose(file);
}

void CydiaAddSource(NSDictionary *source) {
    [Sources_
     setObject:source
     forKey:[NSString stringWithFormat:@"%@:%@:%@", [source objectForKey:@"Type"], [source objectForKey:@"URI"], [source objectForKey:@"Distribution"]]];
}

void CydiaAddSource(NSString *href, NSString *distribution, NSArray *sections) {
    if (href == nil || distribution == nil)
        return;

    CydiaAddSource([NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"deb", @"Type",
        href, @"URI",
        distribution, @"Distribution",
        sections ?: [NSMutableArray array], @"Sections",
    nil]);
}
