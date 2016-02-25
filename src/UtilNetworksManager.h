//
//  UtilNetworksManager.h
//
//
//  Created by qpiu on 2016/2/12.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi/MobileWiFi.h"

@class UtilNetwork;

@interface UtilNetworksManager : NSObject {
	WiFiManagerRef      _manager;
	WiFiDeviceClientRef _client;
	WiFiNetworkRef      _currentNetwork;
	BOOL                _scanning;
	BOOL                _associating;
	NSMutableArray      *_networks;
	int 				_statusCode;
}

@property(nonatomic, retain, readonly) NSArray *networks;
@property(nonatomic, assign, readonly, getter = isScanning) BOOL scanning;
@property(nonatomic, assign, readonly) int statusCode;
@property(nonatomic, assign, getter = isWiFiEnabled) BOOL wiFiEnabled;

+ (id)sharedInstance;
- (void)scan;
//- (void)removeNetwork:(UtilNetwork *)network;
- (void)associateWithNetwork:(UtilNetwork *)network;
- (void)associateWithEncNetwork:(UtilNetwork *)network Password:(NSString *)passwd;
- (void)disassociate;
- (UtilNetwork *)getNetworkWithSSID:(NSString *)ssid;
//- (NSArray *)knownNetworks;
//- (NSString *)interfaceName;

@end
