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

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // 1. Create the master View Controller
    self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    
    // 2. Add the view controller to the Window's content view
    [self.window.contentView addSubview:self.mainViewController.view];
    self.mainViewController.view.frame = ((NSView *)self.window.contentView).bounds;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [self.mainViewController stopBreakWall];
}

@end
