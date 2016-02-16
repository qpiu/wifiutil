//
//  UtilNetworksManager.m
//
//
//  Created by lerlerblur on 2016/2/12.
//
//

#import "UtilNetworksManager.h"
#import "UtilNetwork.h"
#import "Constants.h"

@interface UtilNetworksManager ()

- (void)_scan;
- (void)_clearNetworks;
- (void)_addNetwork:(UtilNetwork *)network;
- (void)_reloadCurrentNetwork;
- (void)_scanDidFinishWithError:(int)error;
- (void)_associationDidFinishWithError:(int)error;
- (WiFiNetworkRef)_currentNetwork;

static void UtilScanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);
static void UtilAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, CFErrorRef error, void *token);

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
		CFArrayRef devices = WiFiManagerClientCopyDevices(_manager);
		if (!devices) {
        fprintf(stderr, "Couldn't get WiFi devices. Bailing.\n");
        exit(EXIT_FAILURE);
    	}
		
		_client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
		CFRetain(_client);    	
    	CFRelease(devices);
		
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
	_scanning = YES;

	// Reload the current network.
	[self _reloadCurrentNetwork];

	// Actually initiate a scan.
	[self _scan];
}

- (void)associateWithNetwork:(UtilNetwork *)network
{
	// Prevent initiating an association if we're already associating.
	if (_associating) {
		LOG_DBG(@"already associating...stop");
		return;
	}

	if (_currentNetwork) {
		// Prevent associating if we're already associated with that network.
		//if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"))]) {
		//	return;
		//} else {
			// Disassociate with the current network before association.
			LOG_DBG(@"Disassociate with the current network");
			[self disassociate];
		//}
	}

	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiNetworkRef net = [network _networkRef];
	if(!net)
		LOG_ERR(@"Cannot get networkRef");

	/*if (net) {
		// XXX: Figure out how Apple sets the username.
		if ([network password])
			WiFiNetworkSetPassword(net, (CFStringRef)[network password]);*/

		[network setIsAssociating:YES];
		_associating = YES;
		LOG_DBG(@"Start associating");
		WiFiDeviceClientAssociateAsync(_client, net, (WiFiDeviceAssociateCallback)UtilAssociationCallback, 0);
		CFRunLoopRun();
	//}
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

- (void)disassociate
{
	WiFiDeviceClientDisassociate(_client);
}

- (UtilNetwork *)getNetworkWithSSID:(NSString *)ssid
{
	for(UtilNetwork *network in _networks)
	{
		if( [[network SSID] isEqualToString:ssid] )
			return network; // network exists
	}
	return nil; // cannot find the network
}

#pragma mark - Private APIs

- (void)_scan
{
	//LOG_DBG(@"Scanning...\n");
	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(_client, (CFDictionaryRef)[NSDictionary dictionary], (WiFiDeviceScanCallback)UtilScanCallback, 0);
	CFRunLoopRun();
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

- (void)_scanDidFinishWithError:(int)error
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);
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
	LOG_DBG(@"Finished association !");
	// Reload the current network.
	[self _reloadCurrentNetwork];
}

#pragma mark - Functions

static void UtilScanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token)
{
	NSString *str = [NSString stringWithFormat:@"Finished scanning! networks: %@", results];
    LOG_OUTPUT(str);
    CFRunLoopStop(CFRunLoopGetCurrent());

	//[[UtilNetworksManager sharedInstance] _clearNetworks];
	for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
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
  	[[UtilNetworksManager sharedInstance] _scanDidFinishWithError:(int)error];
}

static void UtilAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, CFErrorRef error, void *token)
{
	CFRunLoopStop(CFRunLoopGetCurrent());
	// Reload every network's data.
	for (UtilNetwork *network in [[UtilNetworksManager sharedInstance] networks]) {
		[network populateData];

		if (networkRef) {
			[network setIsCurrentNetwork:[[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"))]];
		}
	}

	[[UtilNetworksManager sharedInstance] _associationDidFinishWithError:(int)error];

}

/*static void UtilReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(UtilNetworksManager *)observer _receivedNotificationNamed:(NSString *)name];
}*/

@end
