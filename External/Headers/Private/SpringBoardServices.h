//
//  SpringBoardServices.h
//  Limitless
//
//

// Thanks to http://iphonedevwiki.net/index.php/SBSRelaunchAction
typedef enum {
    None                                     = 0,
    SBSRelaunchOptionsRestartRenderServer    = (1 << 0),
    SBSRelaunchOptionsSnapshot               = (1 << 1),
    SBSRelaunchOptionsFadeToBlack            = (1 << 2),
} SBSRelaunchOptions;

@interface SBSRelaunchAction : NSObject

+ (SBSRelaunchAction *)actionWithReason:(NSString *)reason
                               options:(SBSRelaunchOptions)options
                             targetURL:(NSURL *)url;

@end

@interface SBSRestartRenderServerAction : NSObject

+ (instancetype)restartActionWithTargetRelaunchURL:(NSURL *)targetURL;
@property(readonly, nonatomic) NSURL *targetURL;

@end
