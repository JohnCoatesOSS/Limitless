//
//  FrontBoardServices.h
//  Limitless
//
//  Created by John Coates on 12/1/16.
//  
//

@interface FBSSystemService : NSObject

+ (instancetype)sharedService;
- (void)sendActions:(NSSet *)arg1 withResult:(id)arg2 ;

@end
