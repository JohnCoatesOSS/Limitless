//
//  CFArray+Sort.h
//  Cydia
//
//  Created on 8/29/16.
//

// Insertion Sort

CFIndex SKBSearch_(const void *element,
                   CFIndex elementSize,
                   const void *list,
                   CFIndex count,
                   CFComparatorFunction comparator,
                   void *context);

CFIndex CFBSearch_(const void *element,
                   CFIndex elementSize,
                   const void *list,
                   CFIndex count,
                   CFComparatorFunction comparator,
                   void *context);

void CFArrayInsertionSortValues(CFMutableArrayRef array,
                                CFRange range,
                                CFComparatorFunction comparator,
                                void *context);
