//
//  SwipeActionController.m
//  Limitless
//
//  Created by Thatchapon Unprasert on 12/11/16.
//  Copyright © 2016 Limitless. All rights reserved.
//

#import "SwipeActionController.h"
#define UCLocalize(key) [[NSBundle mainBundle] localizedStringForKey:@ key value:nil table:nil]

@implementation SwipeActionController

+ (instancetype) sharedInstance
{
	static dispatch_once_t p = 0;
	__strong static SwipeActionController *controller = nil;
	dispatch_once(&p, ^{
		controller = [[self alloc] init];
	});
	return controller;
}

- (BOOL) shortLabel
{
	return YES;
}

- (BOOL) autoDismissWhenQueue
{
	return YES;
}

- (BOOL) autoPerform
{
	return YES;
}

- (NSString *) installString
{
	return [self shortLabel] ? @"↓" : UCLocalize("INSTALL");
}

- (NSString *) reinstallString
{
	return [self shortLabel] ? @"↺" : UCLocalize("REINSTALL");
}

- (NSString *) upgradeString
{
	return [self shortLabel] ? @"↑" : UCLocalize("UPGRADE");
}

- (NSString *) removeString
{
	return [self shortLabel] ? @"╳" : UCLocalize("REMOVE");
}

- (NSString *) queueString
{
	return [self shortLabel] ? @"Q" : UCLocalize("QUEUE");
}

- (NSString *) clearString
{
	return [self shortLabel] ? @"⌧" : UCLocalize("CLEAR");
}

- (NSString *) downgradeString
{
	return [self shortLabel] ? @"⇵" : UCLocalize("DOWNGRADE");
}

- (NSString *) buyString
{
	return @"💳";
}

- (NSString *) normalizedString:(NSString *)string
{
	return [string stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

- (NSString *) queueString:(NSString *)action
{
	return [NSString stringWithFormat:@"%@\n%@", [self queueString], action];
}

@end