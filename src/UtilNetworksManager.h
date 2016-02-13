//
//  UtilNetworksManager.h
//
//
//  Created by lerlerblur on 2016/2/12.
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
}

@property(nonatomic, retain, readonly) NSArray *networks;
@property(nonatomic, assign, readonly, getter = isScanning) BOOL scanning;
@property(nonatomic, assign, getter = isWiFiEnabled) BOOL wiFiEnabled;

+ (id)sharedInstance;
- (void)scan;
//- (void)removeNetwork:(WiFiNetworkRef)network;
- (void)associateWithNetwork:(UtilNetwork *)network;
- (void)disassociate;
//- (NSArray *)knownNetworks;
//- (NSString *)interfaceName;

@end
