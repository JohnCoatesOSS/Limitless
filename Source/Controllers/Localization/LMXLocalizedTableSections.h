//
//  LMXLocalizedTableSections.h
//  Limitless
//
//  11/29/16.
//  
//

#import <Foundation/Foundation.h>

@interface LMXLocalizedTableSections : NSObject

// Legacy

@property (class, readwrite) BOOL testModeEnabled;
@property (class, readonly) NSLocale *collationLocale;
@property (class, readonly) NSArray *collationTableIndexTitles;
@property (class, readonly) NSArray *sectionTitles;
@property (class, readonly) NSArray *sectionStartStrings;
@property (class, readonly) NSArray <NSNumber *> *sectionsForIndexTitles;

+ (BOOL)transliterate:(CYString)name
                 pool:(CYPool *)pool
               output:(CYString *)output;

@end
