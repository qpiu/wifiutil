//
//  UtilNetwork.m
//  
//
//  Created by lerlerblur on 2016/2/12.
//
//

//#import <Foundation/Foundation.h>
#import "UtilNetwork.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation UtilNetwork
@synthesize SSID             = _SSID;
@synthesize RSSI             = _RSSI;
@synthesize encryptionModel  = _encryptionModel;
@synthesize BSSID            = _BSSID;
@synthesize username         = _username;
@synthesize password         = _password;
@synthesize vendor           = _vendor;
@synthesize record           = _record;
@synthesize channel          = _channel;
@synthesize APMode           = _APMode;
@synthesize bars             = _bars;
@synthesize isAppleHotspot   = _isAppleHotspot;
@synthesize isCurrentNetwork = _isCurrentNetwork;
@synthesize isAdHoc          = _isAdhoc;
@synthesize isHidden         = _isHidden;
@synthesize isAssociating    = _isAssociating;
@synthesize requiresUsername = _requiresUsername;
@synthesize requiresPassword = _requiresPassword;
@synthesize _networkRef      = _network;

- (id)initWithNetwork:(WiFiNetworkRef)network
{
    self = [super init];
    
    if (self) {
        _network = (WiFiNetworkRef)CFRetain(network);
    }
    
    return self;
}

- (void)dealloc
{
    [_SSID release];
    [_encryptionModel release];
    [_BSSID release];
    [_username release];
    [_password release];
    [_vendor release];
    [_record release];
    CFRelease(_network);
    
    [super dealloc];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ SSID: %@ RSSI: %f Encryption Model: %@ Channel: %i AppleHotspot: %i CurrentNetwork: %i BSSID: %@ AdHoc: %i Hidden: %i Associating: %i", [super description], [self SSID], [self RSSI], [self encryptionModel], [self channel], [self isAppleHotspot], [self isCurrentNetwork], [self BSSID], [self isAdHoc], [self isHidden], [self isAssociating]];
}


- (void)populateData
{
    // SSID
    NSString *SSID = (NSString *)WiFiNetworkGetSSID(_network);
    [self setSSID:SSID];
    
    // RSSI & bars.
    CFNumberRef RSSI = (CFNumberRef)WiFiNetworkGetProperty(_network, CFSTR("RSSI"));
    float strength;
    CFNumberGetValue(RSSI, 12, &strength); // 12: kCFNumberFloatType
    
    [self setRSSI:strength];
    
    CFNumberRef gradedRSSI = (CFNumberRef)WiFiNetworkGetProperty(_network, kWiFiScaledRSSIKey);
    float graded;
    CFNumberGetValue(gradedRSSI, 12, &graded); // 12: kCFNumberFloatType
    
    int bars = (int)ceilf((graded * -1.0f) * -3.0f);
    bars = MAX(1, MIN(bars, 3));
    
    [self setBars:bars];
    
    // Encryption model
    if (WiFiNetworkIsWEP(_network))
        [self setEncryptionModel:@"WEP"];
    else if (WiFiNetworkIsWPA(_network))
        [self setEncryptionModel:@"WPA"];
    else
        [self setEncryptionModel:@"None"];
    
    // Channel
    CFNumberRef networkChannel = (CFNumberRef)WiFiNetworkGetProperty(_network, CFSTR("CHANNEL"));
    
    int channel;
    CFNumberGetValue(networkChannel, 9, &channel); // 9: kCFNumberIntType
    [self setChannel:channel];
    
    // Apple Hotspot
    BOOL isAppleHotspot = WiFiNetworkIsApplePersonalHotspot(_network);
    [self setIsAppleHotspot:isAppleHotspot];
    
    // BSSID
    NSString *BSSID = (NSString *)WiFiNetworkGetProperty(_network, CFSTR("BSSID"));
    [self setBSSID:BSSID];
    
    // AdHoc
    BOOL isAdHoc = WiFiNetworkIsAdHoc(_network);
    [self setIsAdHoc:isAdHoc];
    
    // Hidden
    BOOL isHidden = WiFiNetworkIsHidden(_network);
    [self setIsHidden:isHidden];
    
    // AP Mode
    int APMode = [(NSNumber *)WiFiNetworkGetProperty(_network, CFSTR("AP_MODE")) intValue];
    [self setAPMode:APMode];
    
    // Record
    NSDictionary *record = (NSDictionary *)WiFiNetworkCopyRecord(_network);
    [self setRecord:record];
    [record release];
    
    // Requires username
    BOOL requiresUsername = WiFiNetworkRequiresUsername(_network);
    [self setRequiresUsername:requiresUsername];
    
    // Requires password
    BOOL requiresPassword = WiFiNetworkRequiresPassword(_network);
    [self setRequiresPassword:requiresPassword];
    
}

@end
