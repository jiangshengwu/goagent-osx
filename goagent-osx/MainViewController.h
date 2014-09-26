//
//  MainViewController.h
//  goagent-osx
//
//  Created by Shengwu Jiang on 9/25/14.
//  Copyright (c) 2014 Shengwu Jiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController<NSTextViewDelegate>

@property (strong) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NSClipView *clipView;
@property (strong) IBOutlet NSTextView *textView;
@property (strong) IBOutlet NSButton *startButton;
@property (strong) IBOutlet NSButton *stopButton;
@property (strong) IBOutlet NSButton *autoStartCheckbox;
@property (strong) IBOutlet NSButton *autoScrollCheckbox;
@property (strong) IBOutlet NSTextField *warningLabel;
@property (strong) IBOutlet NSButton *killButton;

/**
 * NSTask
 */
@property (nonatomic, strong) __block NSTask *task;
@property (nonatomic) BOOL isRunning;
@property (nonatomic, strong) NSPipe *pipe;

- (void)stopBreakWall;

@end
