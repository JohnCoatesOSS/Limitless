//
//  APTDownloadItem.mm
//  Limitless
//
//  Created on 12/20/16.
//

#import "Apt.h"
#import "APTDownloadItem-Private.h"

APT_SILENCE_DEPRECATIONS_BEGIN

@interface APTDownloadItem ()

@property pkgAcquire::Item *item;

@end

@implementation APTDownloadItem

// MARK: - Init

- (instancetype)initWithItem:(pkgAcquire::Item *)item {
    self = [super init];

    if (self) {
        _item = item;
    }

    return self;
}

- (BOOL)finished {
    return self.item->Complete;
}

- (APTDownloadState)state {
    pkgAcquire::Item::ItemState state = self.item->Status;
    
    switch (state) {
        case pkgAcquire::Item::StatIdle:
            return APTDownloadStateIdle;
        case pkgAcquire::Item::StatFetching:
            return APTDownloadStateDownloading;
        case pkgAcquire::Item::StatDone:
            return APTDownloadStateDone;
        case pkgAcquire::Item::StatError:
            return APTDownloadStateError;
        case pkgAcquire::Item::StatAuthError:
            return APTDownloadStateAuthenticationError;
        case pkgAcquire::Item::StatTransientNetworkError:
            return APTDownloadStateTransientNetworkError;
    }
}

- (NSString *)errorMessage {
    return @(self.item->ErrorText.c_str());
}

- (NSURL *)url {
    NSString *urlString = @(self.item->DescURI().c_str());
    return [NSURL URLWithString:urlString];
}

@end


APT_SILENCE_DEPRECATIONS_END
