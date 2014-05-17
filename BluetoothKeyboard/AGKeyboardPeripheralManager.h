//
//  AGKeyboardPeripheralManager.h
//  BluetoothKeyboard
//
//  Created by 上田 宗一郎 on 2014/04/11.
//  Copyright (c) 2014年 @Angelworm_. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AGKeyboardPeripheralManager : NSObject <CBPeripheralManagerDelegate>

@property CBPeripheralManager *manager;
@property CBMutableCharacteristic *binput;

- (id)init;
- (BOOL)sendKey:(char)key;
- (void)stop;

@end
