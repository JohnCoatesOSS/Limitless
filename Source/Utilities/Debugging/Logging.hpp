//
//  Logging.hpp
//  Cydia
//
//  Created on 8/30/16.
//


#import "Apt.h"

class CydiaLogCleaner :
public pkgArchiveCleaner
{
protected:
    virtual void Erase(const char *File, std::string Pkg, std::string Ver, struct stat &St) {
        unlink(File);
    }
};
