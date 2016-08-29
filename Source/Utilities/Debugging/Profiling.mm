//
//  Profiling.mm
//  Cydia
//
//  Created on 8/29/16.
//

#import "Profiling.hpp"

#pragma mark - Globals

struct timeval _ltv;
bool _itv;

TimeList times_;

#pragma mark - C Methods

void PrintTimes() {
    for (TimeList::const_iterator i(times_.begin()); i != times_.end(); ++i)
        (*i)->Print();
    std::cerr << "========" << std::endl;
}
