//
//  MainViewController.m
//  goagent-osx
//
//  Created by Shengwu Jiang on 9/25/14.
//  Copyright (c) 2014 Shengwu Jiang. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController () {
    NSMutableDictionary *attrsDictionary;
    NSString *path;
    NSColor *notiColor;
    NSColor *errorColor;
    NSColor *warnColor;
    NSColor *infoColor;
}

@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    notiColor = [NSColor colorWithSRGBRed:72.0/255 green:131.0/255 blue:30.0/255 alpha:1];
    errorColor = [NSColor colorWithSRGBRed:180.0/255 green:51.0/255 blue:34.0/255 alpha:1];
    warnColor = [NSColor colorWithSRGBRed:130.0/255 green:121.0/255 blue:71.0/255 alpha:1];
    infoColor = [NSColor colorWithSRGBRed:220.0/255 green:220.0/255 blue:220.0/255 alpha:1];
    
    _textView.delegate = self;
    [_textView setTextContainerInset:NSSizeFromString(@"5, 5")];
    
    [_stopButton setEnabled:NO];
    
    NSFont *font = [NSFont fontWithName:@"Courier" size:13.0];
    attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:font forKey:NSFontAttributeName];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    path = [mainBundle bundlePath];
    path = [NSString stringWithFormat:@"%@/proxy.py", [path stringByDeletingLastPathComponent]];
//    path = [mainBundle pathForResource:@"startup" ofType:@"sh"];
    NSLog(@"%@", path);
}

- (IBAction)startClick:(id)sender {
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        _isRunning = YES;
        [_startButton setEnabled:NO];
        @try {
            _pipe = [NSPipe pipe];
            [self appendText:@"NOTIFICATION - GoAgent started!\n"];
            [[_pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[_pipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){
                NSData *output = [[_pipe fileHandleForReading] availableData];
                NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self appendText:[NSString stringWithFormat:@"%@\n", outStr]];
                });

                [[_pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            }];
            _task = [[NSTask alloc] init];
            _task.launchPath = @"/usr/bin/python";
            _task.arguments = @[@"/Users/Jiang/Documents/goagent/local/proxy.py"];
            _task.standardOutput = _pipe;
            _task.standardError = _pipe;
            NSLog (@"Start task");
            [_task launch];
            [_stopButton setEnabled:YES];
            [_task waitUntilExit];
        }
        @catch (NSException *exception) {
            NSLog(@"Problem Running Task: %@", [exception description]);
        }
        @finally {
            NSData *output = [[_pipe fileHandleForReading] readDataToEndOfFile];
            NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            [self appendText:[NSString stringWithFormat:@"%@\n", outStr]];
            [_startButton setEnabled:YES];
            _isRunning = NO;
        }
    });
}

- (IBAction)stopClick:(id)sender {
    [_stopButton setEnabled:NO];
    [self appendText:@"NOTIFICATION - GoAgent stopped!\n"];
    [self stopBreakWall];
}

- (void)stopBreakWall {
    if ([_task isRunning]) {
        [_task terminate];
    }
}

- (void)appendMethod:(NSString *)output {
    [self appendText:output];
}

- (void)appendText:(NSString *)text;
{
    //描画を一時的に止める
    [_textView.textStorage beginEditing];
    
    //テキストを追加
    if ([text hasPrefix:@"NOTIFICATION -"]) {
        [attrsDictionary setObject:notiColor forKey:NSForegroundColorAttributeName];
    } else if ([text hasPrefix:@"ERROR -"]) {
        [attrsDictionary setObject:errorColor forKey:NSForegroundColorAttributeName];
    } else if ([text hasPrefix:@"WARNING -"]) {
        [attrsDictionary setObject:warnColor forKey:NSForegroundColorAttributeName];
    } else {
        [attrsDictionary setObject:infoColor forKey:NSForegroundColorAttributeName];
    }
    NSAttributedString *atrstr = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];

    [_textView.textStorage appendAttributedString: atrstr];
    
    //描画再開
    [_textView.textStorage endEditing];
    
    // Scroll to end of textView
    NSRange range;
    range = NSMakeRange([_textView.string length], 0);
    [_textView scrollRangeToVisible:range];
}



@end
