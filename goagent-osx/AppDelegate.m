//
//  AppDelegate.m
//  goagent-osx
//
//  Created by Shengwu Jiang on 9/25/14.
//  Copyright (c) 2014 Shengwu Jiang. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic,strong) IBOutlet MainViewController *mainViewController;

@end

NSString * const UserConfigRunTimes = @"run";
NSString * const UserConfigAutoStart = @"start";
NSString * const UserConfigAutoScroll = @"scroll";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    [self.window.contentView addSubview:self.mainViewController.view];
    self.mainViewController.view.frame = ((NSView *)self.window.contentView).bounds;
    
    // set window title
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [dict valueForKey:@"CFBundleShortVersionString"];
    [self.window setTitle:[NSString stringWithFormat:@"GoAgent for OSX  %@", version]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [self.mainViewController stopBreakWall];
}

+ (AppDelegate *)app {
    return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@end
