//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFReachability.h"
#import "OFSettings.h"
#import "OFDependencies.h"

@interface OFReachability ()
- (void)_setReachabilityFromFlags:(SCNetworkReachabilityFlags)flags;
- (OFReachabilityStatus)status;
- (NSMutableArray*)observers;
- (BOOL)iteratingObservers;
@end

OFReachability* sSharedReachability = nil;

static void ofReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	[sSharedReachability _setReachabilityFromFlags:flags];
}

@implementation OFReachability

#pragma mark -
#pragma mark Life Cycle
#pragma mark -

+ (void)initializeReachability
{
	OFSafeRelease(sSharedReachability);
	sSharedReachability = [OFReachability new];
}

+ (void)shutdownReachability
{
	OFSafeRelease(sSharedReachability);
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		observers = [[NSMutableArray alloc] initWithCapacity:1];
		
		NSString* host = [[NSURL URLWithString:[[OFSettings instance] getSetting:@"server-url"]] host];
		reachability = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
		
		SCNetworkReachabilitySetCallback(reachability, ofReachabilityCallback, NULL);
		SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		
		status = OFReachability_Unknown;
	}
	
	return self;
}

- (void)dealloc
{
	[observers release];
	
	SCNetworkReachabilitySetCallback(reachability, ofReachabilityCallback, NULL);
	SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	CFRelease(reachability);
	[super dealloc];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

+ (void)addObserver:(id)reachabilityObserver
{
    OFAssert(!sSharedReachability.iteratingObservers, @"OFReachabilityObserver: You can't add observers while in a \"reachabilityChangedFrom\" callback.");
	[[sSharedReachability observers] addObject:[NSValue valueWithNonretainedObject:reachabilityObserver]];
}

+ (void)removeObserver:(id)reachabilityObserver
{
    OFAssert(!sSharedReachability.iteratingObservers, @"OFReachabilityObserver: You can't remove observers while in a \"reachabilityChangedFrom\" callback.");
	for (NSValue* observer in [sSharedReachability observers])
	{
		if ([observer nonretainedObjectValue] == reachabilityObserver)
		{
			[[sSharedReachability observers] removeObject:observer];
			break;
		}
	}
}

+ (OFReachabilityStatus)reachability
{
	return [sSharedReachability status];
}

+ (BOOL)isConnectedToInternet
{
	return [sSharedReachability status] == OFReachability_Connected_WiFi ||
            [sSharedReachability status] == OFReachability_Connected_Carrier;
}

#pragma mark -
#pragma mark Internal
#pragma mark -

- (OFReachabilityStatus)status
{
	return status;
}

- (NSMutableArray*)observers
{
	return observers;
}

- (BOOL)iteratingObservers
{
    return iteratingObservers;
}

- (void)_setReachabilityFromFlags:(SCNetworkReachabilityFlags)flags
{
	OFReachabilityStatus oldStatus = status;

	status = OFReachability_Connected_WiFi;
	
	BOOL connectionRequired = (flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired;
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		status = OFReachability_Connected_Carrier;
		connectionRequired = NO;
	}
		
	BOOL reachable = ((flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable) && !connectionRequired;
	if (!reachable)
	{
		status = OFReachability_Not_Connected;
	}
	
    iteratingObservers = YES;
	for (NSValue* observer in observers)
	{
		id observerId = [observer nonretainedObjectValue];
		if ([observerId conformsToProtocol:@protocol(OFReachabilityObserver)])
		{
			[(id<OFReachabilityObserver>)observerId reachabilityChangedFrom:oldStatus to:status];
		}
	}
    iteratingObservers = NO;
}

@end
