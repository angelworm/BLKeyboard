//
//  NSData+AGByteInitializer.m
//  BluetoothKeyboard
//
//  Created by 上田 宗一郎 on 2014/04/21.
//  Copyright (c) 2014年 @Angelworm_. All rights reserved.
//

#import "NSData+AGByteInitializer.h"

@implementation NSData (AGByteInitializer)

+(id)dataWithByte:(char)byte
{
    return [NSData dataWithBytes:&byte length:1];
}

@end
