//
//  main.c
//  wifiutil
//
//  Created by lerlerblur on 2016/2/9.
//  Copyright (c) 2016年 orangegogo. All rights reserved.
//

#import <stdio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <MobileWiFi/MobileWiFi.h>
#import "UtilNetwork.h"
#import "UtilNetworksManager.h"
#import "Constants.h"
#include <String.h>

static WiFiManagerRef _manager;
static void scan_callback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);
static void scan_networks();

int main(int argc, char **argv, char **envp) {
    // insert code here...
    NSString *hello = @"Hello, wifiutil!\n";
    LOG_OUTPUT(hello);
    NSString *str = [NSString stringWithFormat:@"argc = %d\n", argc];
    LOG_DBG(str);
    for (int i = 1; i < argc; i++) {
        NSString *str = [NSString stringWithFormat:@"argv[%d] = %s\n", i, argv[i]];
        LOG_DBG(str);
    }
    
    if (argc < 2) {
        LOG_ERR(@"Specify arguments to use wifiutil.\n");
        return -1;
    }

    NSString *usage = [NSString stringWithUTF8String:argv[1]];
    str = [NSString stringWithFormat:@"wifiutil: %@ \n", usage];
    LOG_DBG(str);
    
    if ([usage isEqualToString:@"scan"])
    {
        //scan_networks();
        [[UtilNetworksManager sharedInstance] scan];
    }
    else if ([usage isEqualToString:@"associate"]) // associate to wifi
    {
        if (argc < 3) {
            LOG_ERR(@"Specify ssid to use wifiutil to associate.\n");
            return -1;
        }
        scan_networks();
    }
    else if ([usage isEqualToString:@"disassociate"]) // disassociate to wifi
    {
        
    }
    return 0;
}

static void scan_networks()
{
    _manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
    
    CFArrayRef devices = WiFiManagerClientCopyDevices(_manager);
    if (!devices) {
        fprintf(stderr, "Couldn't get WiFi devices. Bailing.\n");
        exit(EXIT_FAILURE);
    }
    
    WiFiDeviceClientRef client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
    
    WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    WiFiDeviceClientScanAsync(client, (CFDictionaryRef)[NSDictionary dictionary], (WiFiDeviceScanCallback)scan_callback, 0);
    
    CFRelease(devices);
    
    CFRunLoopRun();
}

static void scan_callback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token)
{
    NSLog(@"Finished scanning! networks: %@", results);
    
    WiFiManagerClientUnscheduleFromRunLoop(_manager);
    CFRelease(_manager);
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

// vim:ft=objc
