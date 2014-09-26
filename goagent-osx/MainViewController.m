//
//  MainViewController.m
//  goagent-osx
//
//  Created by Shengwu Jiang on 9/25/14.
//  Copyright (c) 2014 Shengwu Jiang. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController () {
@private
    NSMutableDictionary *attrsDictionary;
    NSString *path;
    NSColor *notiColor;
    NSColor *errorColor;
    NSColor *warnColor;
    NSColor *infoColor;
    NSUserDefaults *defaults;
}

@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    // record the times that this app opens
    defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:UserConfigRunTimes];
    [defaults setInteger:++count forKey:UserConfigRunTimes];
    [defaults synchronize];
    
    // define font and colors for different outputs
    NSFont *font = [NSFont fontWithName:@"Courier" size:13.0];
    attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:font forKey:NSFontAttributeName];
    notiColor = [NSColor colorWithSRGBRed:72.0/255 green:131.0/255 blue:30.0/255 alpha:1];
    errorColor = [NSColor colorWithSRGBRed:180.0/255 green:51.0/255 blue:34.0/255 alpha:1];
    warnColor = [NSColor colorWithSRGBRed:130.0/255 green:121.0/255 blue:71.0/255 alpha:1];
    infoColor = [NSColor colorWithSRGBRed:220.0/255 green:220.0/255 blue:220.0/255 alpha:1];
    
    _textView.delegate = self;
    [_textView setTextContainerInset:NSSizeFromString(@"5, 5")];
    
    [self initUserDefaults];
    
    NSBundle *bundle = [NSBundle mainBundle];
    path = [[bundle bundlePath] stringByDeletingLastPathComponent];
    if (DEBUG) {
        path = @"/Users/Jiang/Documents/goagent/local/proxy.py";
    } else {
        path = [NSString stringWithFormat:@"%@/proxy.py", path];
    }
    NSLog(@"%@", path);
    
    [self checkProxyStatus];
}

- (IBAction)startClick:(id)sender {
    [self startBreakWall];
}

- (IBAction)stopClick:(id)sender {
    [self stopBreakWall];
}

- (IBAction)killClick:(id)sender {
    [self killGoAgent];
}

/// start goagent proxy
- (void)startBreakWall {
    __block BOOL isFirst = YES;
    __block BOOL startError = NO;
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        _isRunning = YES;
        [_startButton setEnabled:NO];
        @try {
            _pipe = [NSPipe pipe];
            [[_pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[_pipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){
                NSData *output = [[_pipe fileHandleForReading] availableData];
                NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self appendText:outStr];
                    if (isFirst) {
                        [self appendText:@"NOTIFICATION - GoAgent started!\n"];
                        isFirst = NO;
                    }
                    if ([outStr rangeOfString:@"[Errno 48]"].length != 0) {
                        startError = YES;
                    }
                });
                
                [[_pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
            }];
            _task = [[NSTask alloc] init];
            // mac os should have built-in python
            _task.launchPath = @"/usr/bin/python";
            _task.arguments = @[path];
            _task.standardOutput = _pipe;
            _task.standardError = _pipe;
            [_task launch];
            [_stopButton setEnabled:YES];
            [_task waitUntilExit];
        }
        @catch (NSException *exception) {
            NSLog(@"Problem Running startBreakWall: %@", [exception description]);
        }
        @finally {
            NSData *output = [[_pipe fileHandleForReading] readDataToEndOfFile];
            NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            [self appendText:outStr];
            [self appendText:@"NOTIFICATION - GoAgent stopped!\n"];
            if (startError) {
                _warningLabel.textColor = errorColor;
                [_warningLabel setTitleWithMnemonic:@"Other proxy.py is running!"];
                [_warningLabel setHidden:NO];
                [_killButton setHidden:NO];
            } else {
                [_startButton setEnabled:YES];
            }
            [_stopButton setEnabled:NO];
            _isRunning = NO;
        }
    });
}

/// stop goagent proxy
- (void)stopBreakWall {
    if ([_task isRunning]) {
        [_task terminate];
    }
}

/// append text to a non-editable textview
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
    if ([defaults boolForKey:UserConfigAutoScroll]) {
        NSRange range;
        range = NSMakeRange([_textView.string length], 0);
        [_textView scrollRangeToVisible:range];
    }
}

#pragma mark - read from or write to NSUserDefaults

- (void)initUserDefaults {
    if ([defaults integerForKey:UserConfigRunTimes] == 1) {
        [defaults setBool:NO forKey:UserConfigAutoStart];
        [defaults setBool:YES forKey:UserConfigAutoScroll];
        [defaults synchronize];
    }
    if ([defaults boolForKey:UserConfigAutoStart]) {
        [_autoStartCheckbox setState:NSOnState];
    }
    if ([defaults boolForKey:UserConfigAutoScroll]) {
        [_autoScrollCheckbox setState:NSOnState];
    }
}

- (IBAction)autoStartChange:(id)sender {
    [defaults setBool:_autoStartCheckbox.state == NSOnState forKey:UserConfigAutoStart];
    [defaults synchronize];
}

- (IBAction)autoScrollChange:(id)sender {
    [defaults setBool:_autoScrollCheckbox.state == NSOnState forKey:UserConfigAutoScroll];
    [defaults synchronize];
}

/// check whether the python proxy.py is running
- (void)checkProxyStatus {
    [self runScriptWithAgrs:@[[[NSBundle mainBundle] pathForResource:@"script" ofType:@"sh"], @"-c"] waitUntilExit:YES usingBlock:^(NSString *result) {
        if (![result compare:@""]) {
            [_startButton setEnabled:YES];
            if ([defaults boolForKey:UserConfigAutoStart]) {
                [self startBreakWall];
            }
        } else {
            [self appendText:@"ERROR - Other proxy.py is running!\n"];
            [self appendText:result];
            _warningLabel.textColor = errorColor;
            [_warningLabel setTitleWithMnemonic:@"Other proxy.py is running!"];
            [_warningLabel setHidden:NO];
            [_killButton setHidden:NO];
        }
    }];
}

/// kill existing proxy.py process
-(void)killGoAgent {
    [self runScriptWithAgrs:@[[[NSBundle mainBundle] pathForResource:@"script" ofType:@"sh"], @"-k"] waitUntilExit:YES usingBlock:^(NSString *result) {
        if (![result compare:@""]) {
            [_killButton setHidden:YES];
            _warningLabel.textColor = notiColor;
            [self appendText:@"NOTIFICATION - Killed successfully!\n"];
            [_warningLabel setTitleWithMnemonic:@"Killed successfully!"];
            [_startButton setEnabled:YES];
            [NSThread sleepForTimeInterval:2];
            [_warningLabel setHidden:YES];
        }
    }];
}

/// run sh with callback block
- (void)runScriptWithAgrs:(NSArray *)args waitUntilExit:(BOOL)wait usingBlock:(void(^)(NSString *result))block {
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        _pipe = [NSPipe pipe];
        NSFileHandle *readHandle = [_pipe fileHandleForReading];
        @try {
            _task = [[NSTask alloc] init];
            _task.launchPath = @"/bin/sh";
            _task.arguments = args;
            _task.standardOutput = _pipe;
            _task.standardError = _pipe;
            [_task launch];
            if (wait) {
                [_task waitUntilExit];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Problem Running Script - %@: %@", args.count != 0 ? args[0] : @"unknown", [exception description]);
        }
        @finally {
            NSData *output = [readHandle readDataToEndOfFile];
            NSString *result = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            NSLog(@"Script: %@\nArguments: %@\nOutput: %@", args.count > 0 ? args[0] : @"unknown", args.count > 1 ? args[1] : @"", result);
            block(result);
        }
    });
}



@end
