//
//  UtilNetworksManager.m
//
//
//  Created by lerlerblur on 2016/2/12.
//
//

#import "UtilNetworksManager.h"
#import "UtilNetwork.h"

@interface UtilNetworksManager ()

- (void)_scan;
- (void)_clearNetworks;
- (void)_addNetwork:(UtilNetwork *)network;
- (void)_receivedNotificationNamed:(NSString *)name;
- (void)_reloadCurrentNetwork;
- (void)_scanDidFinishWithError:(int)error;
- (void)_associationDidFinishWithError:(int)error;
- (WiFiNetworkRef)_currentNetwork;

static void UtilScanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);
static void UtilAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *token);
//static void UtilReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@end

static UtilNetworksManager *_sharedInstance = nil;

@implementation UtilNetworksManager
@synthesize networks = _networks;
@synthesize scanning = _scanning;

+ (id)sharedInstance
{
	@synchronized(self) {
		if (!_sharedInstance)
			_sharedInstance = [[self alloc] init];

		return _sharedInstance;
	}
}

- (id)init
{
	self = [super init];

	if (self) {
		_manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
        NSLog(@"WiFiManagerClientCreate\n");
		CFArrayRef devices = WiFiManagerClientCopyDevices(_manager);
		if (devices) {
			_client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
			CFRetain(_client);
            NSLog(@"_client\n");

			//CFRelease(devices);
		}

		_networks = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void)dealloc
{
	//CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, NULL, NULL);

	CFRelease(_currentNetwork);
	CFRelease(_client);
	CFRelease(_manager);

	[self _clearNetworks];

	[super dealloc];
}

- (void)scan
{
	// Prevent initiating a scan when we're already scanning.
	if (_scanning)
		return;
    NSLog(@"Scan...\n");
	_scanning = YES;

	// Post a notification to tell the controller that scanning has started.
	//[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidStartScanning object:nil];

	// Reload the current network.
	//[self _reloadCurrentNetwork];

	// Actually initiate a scan.
	[self _scan];
}

- (void)associateWithNetwork:(UtilNetwork *)network
{
	// Prevent initiating an association if we're already associating.
	if (_associating)
		return;

	if (_currentNetwork) {
		// Prevent associating if we're already associated with that network.
		if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"))]) {
			return;
		} else {
			// Disassociate with the current network before associating with a new one.
			[self disassociate];
		}
	}

	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiNetworkRef net = [network _networkRef];

	if (net) {
		// XXX: Figure out how Apple sets the username.
		if ([network password])
			WiFiNetworkSetPassword(net, (CFStringRef)[network password]);

		WiFiDeviceClientAssociateAsync(_client, net, UtilAssociationCallback, NULL);
		[network setIsAssociating:YES];
		_associating = YES;
	}

	// Post a notification to tell the controller that association has started.
	//[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidStartAssociating object:nil];
}

- (BOOL)isWiFiEnabled
{
	CFBooleanRef enabled = WiFiManagerClientCopyProperty(_manager, CFSTR("AllowEnable"));

	BOOL value = CFBooleanGetValue(enabled);

	CFRelease(enabled);

	return value;
}

- (void)setWiFiEnabled:(BOOL)enabled
{
	// XXX: What.
	CFBooleanRef value = (enabled ? kCFBooleanTrue : kCFBooleanFalse);

	WiFiManagerClientSetProperty(_manager, CFSTR("AllowEnable"), value);
}

- (NSString *)interfaceName
{
	return (NSString *)WiFiDeviceClientGetInterfaceName(_client);
}

- (NSArray *)knownNetworks
{
	return [(NSArray *)WiFiManagerClientCopyNetworks(_manager) autorelease];
}

- (void)removeNetwork:(WiFiNetworkRef)network
{
	WiFiManagerClientRemoveNetwork(_manager, network);
}

- (void)disassociate
{
	WiFiDeviceClientDisassociate(_client);

	//[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidDisassociate object:nil];
}

#pragma mark - Private APIs

- (void)_scan
{
    NSLog(@"_scan...\n");
	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(_client, (CFDictionaryRef)[NSDictionary dictionary], (WiFiDeviceScanCallback)UtilScanCallback, 0);
}

- (void)_clearNetworks
{
	[_networks removeAllObjects];
}

- (void)_addNetwork:(UtilNetwork *)network
{
	[_networks addObject:network];
}

- (WiFiNetworkRef)_currentNetwork
{
	return _currentNetwork;
}

- (void)_reloadCurrentNetwork
{
	if (_currentNetwork) {
		CFRelease(_currentNetwork);
		_currentNetwork = nil;
	}

	_currentNetwork = WiFiDeviceClientCopyCurrentNetwork(_client);
}

- (void)_receivedNotificationNamed:(NSString *)name
{
    if ([name isEqualToString:@"com.apple.wifi.powerstatedidchange"]) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiPowerStateDidChange object:nil];
    } else if ([name isEqualToString:@"com.apple.wifi.linkdidchange"]) {
        //[self _reloadCurrentNetwork];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiLinkDidChange object:nil];
    }
}

- (void)_scanDidFinishWithError:(int)error
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);

	// Reverse the array so that networks with the highest signal strength go to the top.
	NSArray *tempNetworks = [[_networks reverseObjectEnumerator] allObjects];
	[_networks removeAllObjects];
	[_networks addObjectsFromArray:tempNetworks];

	_scanning = NO;

}

- (void)_associationDidFinishWithError:(int)error
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);

	for (UtilNetwork *network in [[UtilNetworksManager sharedInstance] networks]) {
		if ([network isAssociating])
			[network setIsAssociating:NO];
	}

	_associating = NO;

	// Reload the current network.
	[self _reloadCurrentNetwork];

	if (error != 0) {
		//NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:error], kDMErrorValueKey, nil];
		//[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerAssociatingDidFail object:nil userInfo:userInfo];
	} else {
		// Post a notification to tell the controller that association has finished.
		//[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishAssociating object:nil];
	}
}

#pragma mark - Functions

static void UtilScanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token)
{
    NSLog(@"Callback \n");
    NSLog(@"Finished scanning! networks: %@", results);
	[[UtilNetworksManager sharedInstance] _clearNetworks];
    

	/*for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
		WiFiNetworkRef networkRef = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);

		UtilNetwork *network = [[UtilNetwork alloc] initWithNetwork:networkRef];
		[network populateData];

		WiFiNetworkRef currentNetwork = [[UtilNetworksManager sharedInstance] _currentNetwork];

		// WiFiNetworkGetProperty() crashes if the network parameter is NULL therefore we need to check if it exists first.
		if (currentNetwork) {
			if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(currentNetwork, CFSTR("BSSID"))])
				[network setIsCurrentNetwork:YES];
		}

		[[UtilNetworksManager sharedInstance] _addNetwork:network];

		[network release];
	}

	[[UtilNetworksManager sharedInstance] _scanDidFinishWithError:error];*/
}

static void UtilAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *token)
{
	// Reload every network's data.
	for (UtilNetwork *network in [[UtilNetworksManager sharedInstance] networks]) {
		[network populateData];

		if (networkRef) {
			[network setIsCurrentNetwork:[[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"))]];
		}
	}

	[[UtilNetworksManager sharedInstance] _associationDidFinishWithError:error];
}

/*static void UtilReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(UtilNetworksManager *)observer _receivedNotificationNamed:(NSString *)name];
}*/

@end
