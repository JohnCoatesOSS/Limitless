//
//  LMXAPTStatus.h
//  Limitless
//
//  Created on 12/6/16.
//
#import "Apt.h"
#import "CancelStatus.hpp"

class LMXAptStatus : public CancelStatus {
private:
    NSObject *delegate_;
    
public:
    LMXAptStatus() {
        delegate_ = nil;
    }
    
    void setDelegate(NSObject *delegate) {
        delegate_ = delegate;
    }
    
    virtual void Fetch(pkgAcquire::ItemDesc &desc) {
        NSString *name = @(desc.ShortDesc.c_str());
        NSLog(@"fetch: %@", name);
//        NSString *name([NSString stringWithUTF8String:desc.ShortDesc.c_str()]);
//        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithFormat:UCLocalize("DOWNLOADING_"), name] ofType:kCydiaProgressEventTypeStatus forItemDesc:desc]);
//        [delegate_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
    }
    
    virtual void Done(pkgAcquire::ItemDesc &desc) {
        NSString *name = @(desc.ShortDesc.c_str());
        NSLog(@"done: %@", name);
//        NSString *name([NSString stringWithUTF8String:desc.ShortDesc.c_str()]);
//        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithFormat:Colon_, UCLocalize("DONE"), name] ofType:kCydiaProgressEventTypeStatus forItemDesc:desc]);
//        [delegate_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
    }
    
    virtual void Fail(pkgAcquire::ItemDesc &desc) {
        if (
            desc.Owner->Status == pkgAcquire::Item::StatIdle ||
            desc.Owner->Status == pkgAcquire::Item::StatDone
            )
            return;
        
        std::string &error(desc.Owner->ErrorText);
        if (error.empty()) {
            return;
        }
        
        NSString *errorString = @(error.c_str());
        NSLog(@"Fail: %@", errorString);
        
//
//        CydiaProgressEvent *event([CydiaProgressEvent eventWithMessage:[NSString stringWithUTF8String:error.c_str()] ofType:kCydiaProgressEventTypeError forItemDesc:desc]);
//        [delegate_ performSelectorOnMainThread:@selector(addProgressEvent:) withObject:event waitUntilDone:YES];
    }
    
    virtual bool Pulse_(pkgAcquire *Owner) {
//        double percent(
//                       double(CurrentBytes + CurrentItems) /
//                       double(TotalBytes + TotalItems)
//                       );
        
//        [delegate_ performSelectorOnMainThread:@selector(setProgressStatus:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                                                         [NSNumber numberWithDouble:percent], @"Percent",
//                                                                                         
//                                                                                         [NSNumber numberWithDouble:CurrentBytes], @"Current",
//                                                                                         [NSNumber numberWithDouble:TotalBytes], @"Total",
//                                                                                         [NSNumber numberWithDouble:CurrentCPS], @"Speed",
//                                                                                         nil] waitUntilDone:YES];
//        
//        return ![delegate_ isProgressCancelled];
        return true;
    }
    
    virtual void Start() {
        pkgAcquireStatus::Start();
//        [delegate_ performSelectorOnMainThread:@selector(setProgressCancellable:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
    }
    
    virtual void Stop() {
        pkgAcquireStatus::Stop();
//        [delegate_ performSelectorOnMainThread:@selector(setProgressCancellable:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
//        [delegate_ performSelectorOnMainThread:@selector(setProgressStatus:) withObject:nil waitUntilDone:YES];
    }
};
