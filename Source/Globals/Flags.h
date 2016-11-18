//
//  Flags.h
//  Cydia
//
//  Created on 8/29/16.
//

#define ForRelease 0
#define TraceLogging (0 && !ForRelease)
#define HistogramInsertionSort (0 && !ForRelease)
#define ProfileTimes (0 && !ForRelease)
#define ForSaurik (1 && !ForRelease)
#define LogBrowser (1 && !ForRelease)
#define TrackResize (0 && !ForRelease)
#define ManualRefresh (1 && !ForRelease)
#define ShowInternals (0 && !ForRelease)
#define AlwaysReload (0 && !ForRelease)