//
//  AppDelegate.h
//  goagent-osx
//
//  Created by Shengwu Jiang on 9/25/14.
//  Copyright (c) 2014 Shengwu Jiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

/// User config key
extern NSString * const UserConfigRunTimes;
extern NSString * const UserConfigAutoStart;
extern NSString * const UserConfigAutoScroll;

+ (AppDelegate *)app;

@end


