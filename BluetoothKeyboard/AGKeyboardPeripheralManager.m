//
//  AGKeyboardPeripheralManager.m
//  BluetoothKeyboard
//
//  Created by 上田 宗一郎 on 2014/04/11.
//  Copyright (c) 2014年 @Angelworm_. All rights reserved.
//

#import "AGKeyboardPeripheralManager.h"
#import "NSData+AGByteInitializer.h"

#define kServiceUUID [CBUUID UUIDWithString: @"1812"]

@implementation AGKeyboardPeripheralManager

@synthesize manager;
@synthesize binput;

-(id)init
{
    self = [super init];
    if(self) {
        manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

- (BOOL)sendKey:(char)key
{
    char packet[] = {
        key, // keycode
        0x00, // padding
        0x00, // LED, padding
        0x00, 0x00, key, 0x00, 0x00, 0x00, // keycodes
        0x00, 0x00 // vendor defined
    };
    
    BOOL ret = [manager updateValue:[NSData dataWithBytes:packet length:sizeof(packet)]
                  forCharacteristic:binput
               onSubscribedCentrals:nil];
    NSLog(@"type:%c, succ:%@", key, ret == YES ? @"YES" : @"NO");
//    NSLog(@"dd:%@", manager)
    return ret;
}

-(void)stop {
    [manager stopAdvertising];
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    NSLog(@"state: %@", peripheral.state == CBPeripheralManagerStatePoweredOn ? @"YES" : @"NO");
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSMutableArray *characteristics = [[NSMutableArray alloc] init];
        
        //// HID device
        
        // Protocol Mode Characteristic
        [characteristics addObject:[[CBMutableCharacteristic alloc]
                                    initWithType: [CBUUID UUIDWithString: @"2A4E"]
                                    properties: CBCharacteristicPropertyRead | CBCharacteristicPropertyWriteWithoutResponse
                                    value: nil
                                    permissions: CBAttributePermissionsReadable | CBAttributePermissionsWriteable]];

        // Report Map
        [characteristics addObject:[[CBMutableCharacteristic alloc]
                                    initWithType: [CBUUID UUIDWithString: @"2A4B"]
                                    properties: CBCharacteristicPropertyRead
                                    value: nil
                                    permissions: CBAttributePermissionsReadable]];
        
        // Boot Keyboard Input Report
        binput = [[CBMutableCharacteristic alloc]
                  initWithType: [CBUUID UUIDWithString: @"2A22"]
                  properties: CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                  value: nil
                  permissions: CBAttributePermissionsReadable];
        [characteristics addObject:binput];
         
        // Boot Keyboard Output Report
        [characteristics addObject:[[CBMutableCharacteristic alloc]
                                    initWithType: [CBUUID UUIDWithString: @"2A32"]
                                    properties: CBCharacteristicPropertyRead |
                                                CBCharacteristicPropertyWrite |
                                                CBCharacteristicPropertyWriteWithoutResponse
                                    value: nil
                                    permissions: CBAttributePermissionsReadable | CBAttributePermissionsWriteable]];

        // HID Information
        [characteristics addObject:[[CBMutableCharacteristic alloc]
                                    initWithType: [CBUUID UUIDWithString: @"2A4A"]
                                    properties: CBCharacteristicPropertyRead
                                    value: nil
                                    permissions: CBAttributePermissionsReadable]];

        // HID Control Point
        [characteristics addObject:[[CBMutableCharacteristic alloc]
                                    initWithType: [CBUUID UUIDWithString: @"2A4C"]
                                    properties: CBCharacteristicPropertyWriteWithoutResponse
                                    value: nil
                                    permissions: CBAttributePermissionsReadable | CBAttributePermissionsWriteable]];
        
        CBMutableService *HIDservice = [[CBMutableService alloc] initWithType:kServiceUUID
                                                                      primary:YES];
        HIDservice.characteristics = characteristics;
        [manager addService:HIDservice];
        
        //// Battery Service
        CBMutableService *BATservice = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString: @"180F"]
                                                                      primary:YES];
        // Battery Level
        BATservice.characteristics = @[[[CBMutableCharacteristic alloc]
                                        initWithType: [CBUUID UUIDWithString: @"2A19"]
                                        properties: CBCharacteristicPropertyRead
                                        value: nil
                                        permissions: CBAttributePermissionsReadable]];
        [manager addService:BATservice];
        
        /*
        //// Device Information
        CBMutableService *DIservice = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString: @"180A"]
                                                                      primary:YES];
        // PnP ID
        DIservice.characteristics = @[[[CBMutableCharacteristic alloc]
                                        initWithType: [CBUUID UUIDWithString: @"2A50"]
                                        properties: CBCharacteristicPropertyRead
                                        value: nil
                                        permissions: CBAttributePermissionsReadable]];
        [manager addService:DIservice];
        */
        NSDictionary *advertising = @{
                                      CBAdvertisementDataLocalNameKey: @"AngelType",
                                      CBAdvertisementDataServiceUUIDsKey: @[//[CBUUID UUIDWithString: @"180A"],
                                                                            kServiceUUID,
                                                                            [CBUUID UUIDWithString: @"2A19"]],
                                      };
        [manager startAdvertising:advertising];
    }
    

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (error) {
        NSLog(@"start add service err: %@", error.localizedDescription);
    } else {
        NSLog(@"service add successfull: %@", service.UUID.description);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    if (error) {
        NSLog(@"start adv err: %@", error.localizedDescription);
    } else {
        NSLog(@"advertising successfull");
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"central: %@", characteristic.UUID.description);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"data read request: %@, (offset:%lu)", request.characteristic.UUID.description, (unsigned long)request.offset);
    
    if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A4E"]]) {
        // Protocol Mode Characteristic
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A4B"]]) {
        // Report Map
        char data[] =
        {
            0x05, 0x01,                 // Usage Page (Generic Desktop)
            0x09, 0x06,                 // Usage (Keyboard)
            0xA1, 0x01,                 // Collection (Application)
            0x85, 0x01,                 //     Report Id (1)
            0x05, 0x07,                 //     Usage Page (Key Codes)
            0x19, 0xe0,                 //     Usage Minimum (224)
            0x29, 0xe7,                 //     Usage Maximum (231)
            0x15, 0x00,                 //     Logical Minimum (0)
            0x25, 0x01,                 //     Logical Maximum (1)
            0x75, 0x01,                 //     Report Size (1)
            0x95, 0x08,                 //     Report Count (8)
            0x81, 0x02,                 //     Input (Data, Variable, Absolute)
            
            0x95, 0x01,                 //     Report Count (1)
            0x75, 0x08,                 //     Report Size (8)
            0x81, 0x01,                 //     Input (Constant) reserved byte(1)
            
            0x95, 0x05,                 //     Report Count (5)
            0x75, 0x01,                 //     Report Size (1)
            0x05, 0x08,                 //     Usage Page (Page# for LEDs)
            0x19, 0x01,                 //     Usage Minimum (1)
            0x29, 0x05,                 //     Usage Maximum (5)
            0x91, 0x02,                 //     Output (Data, Variable, Absolute), Led report
            0x95, 0x01,                 //     Report Count (1)
            0x75, 0x03,                 //     Report Size (3)
            0x91, 0x01,                 //     Output (Data, Variable, Absolute), Led report padding
            
            0x95, 0x06,                 //     Report Count (6)
            0x75, 0x08,                 //     Report Size (8)
            0x15, 0x00,                 //     Logical Minimum (0)
            0x25, 0x65,                 //     Logical Maximum (101)
            0x05, 0x07,                 //     Usage Page (Key codes)
            0x19, 0x00,                 //     Usage Minimum (0)
            0x29, 0x65,                 //     Usage Maximum (101)
            0x81, 0x00,                 //     Input (Data, Array) Key array(6 bytes)
            
            0x09, 0x05,                 //     Usage (Vendor Defined)
            0x15, 0x00,                 //     Logical Minimum (0)
            0x26, 0xFF, 0x00,           //     Logical Maximum (255)
            0x75, 0x08,                 //     Report Count (2)
            0x95, 0x02,                 //     Report Size (8 bit)
            0xB1, 0x02,                 //     Feature (Data, Variable, Absolute)
            
            0xC0,                        // End Collection (Application)
        };

        request.value = [NSData dataWithBytes:data + request.offset length:sizeof(data) - request.offset];
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A22"]]) {
        // Boot Keyboard Input Report
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A32"]]) {
        // Boot Keyboard Output Report
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A4A"]]) {
        // HID Information
        char data[] = {0x01, 0x01, 0x00, 0b11000000};
        request.value = [NSData dataWithBytes:data length:sizeof(data)];
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A4C"]]) {
        // HID Control Point
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A19"]]) {
        // Battery Level
        char data[] = {100};
        request.value = [NSData dataWithBytes:data length:sizeof(data)];
    } else if([request.characteristic.UUID isEqual:[CBUUID UUIDWithString: @"2A50"]]) {
        // PnP ID
        char data[] = {1, 0x05, 0xac, 0x00, 0x00, 0x00, 0x00};
        request.value = [NSData dataWithBytes:data length:sizeof(data)];
    }

    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
   didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"data write request");
    for (CBATTRequest *r in requests) {
        NSLog(@"\t%@", r.description);
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"hoge");
}

- (void)dealloc
{
    [manager stopAdvertising];
}
@end
