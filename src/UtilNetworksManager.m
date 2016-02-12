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
- (WiFiNetworkRef)_currentNetwork;

static void UtilScanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);

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

	/*CFRelease(_currentNetwork);
	CFRelease(_client);
	CFRelease(_manager);

	[self _clearNetworks];
*/
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

#pragma mark - Private APIs

- (void)_scan
{
	LOG_DBG(@"Scanning...\n");
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
  
}

/*static void UtilAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *token)
{
	// Reload every network's data.
	for (UtilNetwork *network in [[UtilNetworksManager sharedInstance] networks]) {
		[network populateData];

		if (networkRef) {
			[network setIsCurrentNetwork:[[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"))]];
		}
	}

	[[UtilNetworksManager sharedInstance] _associationDidFinishWithError:error];

}*/

/*static void UtilReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(UtilNetworksManager *)observer _receivedNotificationNamed:(NSString *)name];
}*/

@end
