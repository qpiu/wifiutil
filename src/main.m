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

int getUsageType(NSString *usage);

int main(int argc, char **argv, char **envp) {
    // insert code here...
    NSString *hello = @"Hello, wifiutil!";
    LOG_OUTPUT(hello);
    NSString *str = [NSString stringWithFormat:@"argc = %d", argc];
    LOG_DBG(str);
    for (int i = 1; i < argc; i++) {
        NSString *str = [NSString stringWithFormat:@"argv[%d] = %s", i, argv[i]];
        LOG_DBG(str);
    }
    
    if (argc < 2) {
        LOG_ERR(@"Specify arguments to use wifiutil.");
        return -1;
    }

    NSString *usage = [NSString stringWithUTF8String:argv[1]];
    str = [NSString stringWithFormat:@"wifiutil: %@", usage];
    LOG_DBG(str);
    int usageType = getUsageType(usage);
    switch (usageType)   
    {
        case 0: // scan
            [[UtilNetworksManager sharedInstance] scan];
            break;
        case 1: // associate: wifiutil associate <ssid> || wifiutil associate <ssid> -p <passwd>
            // Argument parsing
            if (argc < 3) {
                LOG_ERR(@"Specify SSID to use wifiutil to associate.");
                return -1;
            }
            NSString *conn_SSID = [NSString stringWithUTF8String:argv[2]];
            NSString *passwd = nil;
            if (argc > 3) { // associate with encrypted network
                if (argc == 4) {
                    LOG_ERR(@"Invalid argument format.");
                    return -1;
                }
                if ( [[NSString stringWithUTF8String:argv[3]] isEqualToString:@"-p"] ) {
                    passwd = [NSString stringWithUTF8String:argv[4]];
                    str = [NSString stringWithFormat:@"Prepare to associate with network %@, passwd: %@", conn_SSID, passwd]; 
                    LOG_DBG(str);
                }
                else {
                    LOG_ERR(@"Invalid argument format.");
                    return -1;
                }
            }   
            else { // associate with open network
                str = [NSString stringWithFormat:@"Prepare to associate with network %@", conn_SSID]; 
                LOG_DBG(str);
            }

            // Scan networks first, and get the network instance with the specified SSID.
            UtilNetworksManager *manager = [UtilNetworksManager sharedInstance];
            [manager scan];

            UtilNetwork *conn_Network = [manager getNetworkWithSSID: conn_SSID];
            if (conn_Network)
            {
                str = [NSString stringWithFormat:@"Found network %@ :)", [conn_Network SSID]];
                LOG_OUTPUT(str);
                if ( [[conn_Network encryptionModel] isEqualToString:@"None"]) { // Open network
                    [manager associateWithNetwork: conn_Network];
                }
                else if ( ![[conn_Network encryptionModel] isEqualToString:@"None"]) { // Encrypted network 
                    if (!passwd)
                    {
                        LOG_ERR(@"Specify PASSWORD to use associate with encrypted network.");
                        [manager dealloc];
                        return -1;
                    }
                    [manager associateWithEncNetwork: conn_Network Password: passwd];
                }
            }
            else
            {
                str = [NSString stringWithFormat:@"Can not find network %@ :(", conn_SSID];
                LOG_ERR(str);
                [manager dealloc];
                return -1;
            }
            break;

        case 2: // disassociate
            [[UtilNetworksManager sharedInstance] disassociate];
            break;

        case 3: // enable-wifi
            //UtilNetworksManager *manager = [UtilNetworksManager sharedInstance];
            str = [NSString stringWithFormat:@"Enable WiFi on iPhone."]; 
            LOG_DBG(str);
            [[UtilNetworksManager sharedInstance] setWiFiEnabled: YES];
            break;

        case 4: // disable-wifi
            //UtilNetworksManager *manager = [UtilNetworksManager sharedInstance];
            str = [NSString stringWithFormat:@"Disable WiFi on iPhone."]; 
            LOG_DBG(str);
            [[UtilNetworksManager sharedInstance] setWiFiEnabled: NO];
            break;

        case 5: // ping
            if (argc < 3) {
            LOG_ERR(@"Specify IP to use wifiutil to ping.\n");
            return -1;
            }
            NSString *ping_ip = [NSString stringWithUTF8String:argv[2]];

            // execute ping
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
            break;

        default:
            LOG_ERR(@"Invalid usage >__< ");
            break;
    }

    return 0;
}

int getUsageType(NSString *usage)
{
    if ([usage isEqualToString:@"scan"]) {
        return 0;
    }
    else if ([usage isEqualToString:@"associate"]) {
        return 1;
    }
    else if ([usage isEqualToString:@"disassociate"]) {
        return 2;
    }
    else if ([usage isEqualToString:@"enable-wifi"]) {
        return 3;
    }
    else if ([usage isEqualToString:@"disable-wifi"]) {
        return 4;
    }
    else if ([usage isEqualToString:@"ping"]) {
        return 5;
    }
    else {
        return -1;
    }
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
