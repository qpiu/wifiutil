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
#import <Foundation/NSTask.h>
#import "UtilNetwork.h"
#import "UtilNetworksManager.h"
#import "Constants.h"
#include <String.h>

//static WiFiManagerRef _manager;
//static void scan_callback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);
//static void scan_networks();

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
        [[UtilNetworksManager sharedInstance] scan];
    }
    else if ([usage isEqualToString:@"associate"]) // associate to wifi
    {
        if (argc < 3) {
            LOG_ERR(@"Specify ssid to use wifiutil to associate.\n");
            return -1;
        }
        NSString *connect_SSID = [NSString stringWithUTF8String:argv[2]];
        UtilNetworksManager *manager = [UtilNetworksManager sharedInstance];
        [manager scan];
        UtilNetwork *conn_Network = [manager getNetworkWithSSID: connect_SSID];
        if(conn_Network)
        {
            str = [NSString stringWithFormat:@"Found network %@ :)", [conn_Network SSID]];
            LOG_OUTPUT(str);
            [manager associateWithNetwork: conn_Network];

        }
        else
        {
            str = [NSString stringWithFormat:@"Can not find network %@ :(", connect_SSID];
            LOG_ERR(str);
            return -1;
        }

    }
    else if ([usage isEqualToString:@"disassociate"]) // disassociate to wifi
    {
        UtilNetworksManager *manager = [UtilNetworksManager sharedInstance];
        [manager disassociate];
    }
    else if ([usage isEqualToString:@"ping"])
    {
        if (argc < 3) {
            LOG_ERR(@"Specify IP to use wifiutil to ping.\n");
            return -1;
        }
        NSString *ping_ip = [NSString stringWithUTF8String:argv[2]];

        // execute ping
        //int pid = [[NSProcessInfo processInfo] processIdentifier];
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/ping";
        task.arguments = @[@"-i", @"0.2", @"-c", @"50", ping_ip];
        task.standardOutput = pipe;
        [task launch];

        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        LOG_OUTPUT(output);
        LOG_DBG(@"Ping Finished !");
    }
    else
    {
        str = [NSString stringWithFormat:@"Invalid argument: %@", usage];
        LOG_ERR(str);
        return -1;
    }
    return 0;
}

/*static void scan_networks()
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
}*/

// vim:ft=objc
