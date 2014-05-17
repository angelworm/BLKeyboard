//
//  AGAppDelegate.m
//  BluetoothKeyboard
//
//  Created by 上田 宗一郎 on 2014/04/10.
//  Copyright (c) 2014年 @Angelworm_. All rights reserved.
//

#import "AGAppDelegate.h"
#import "AGKeyboardPeripheralManager.h"

@implementation AGAppDelegate {
    AGKeyboardPeripheralManager *kpm;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    kpm = [[AGKeyboardPeripheralManager alloc] init];
}

- (IBAction)keytype:(NSTextField *)sender {
    [kpm sendKey:[sender.stringValue characterAtIndex:sender.stringValue.length-1]];
}
- (IBAction)stop:(id)sender {
    [kpm stop];
}

@end
