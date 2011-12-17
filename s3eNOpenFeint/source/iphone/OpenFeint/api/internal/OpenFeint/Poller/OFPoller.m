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

#import "OFPoller.h"
#import "OFQueryStringWriter.h"
#import "OFProviderProtocol.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFResource.h"
#import "OFPollerResourceType.h"
#import <objc/runtime.h>
#import "OFTimerHeartbeat.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+Settings.h"
#import "OFPaginatedSeries.h"
#import "OFResource+ObjC.h"
#import "OFXmlElement.h"
#import "OFDependencies.h"

NSString* OFPollerNotificationKeyForResources = @"OFPollerNotificationKeyResources";

@implementation OFPoller

- (id)initWithProvider:(NSObject<OFProviderProtocol>*)provider sourceUrl:(NSString*)sourceUrl;
{
	self = [super init];
	if (self != nil)
	{
		mProvider = [provider retain];
		mChronologicalResourceTypes = [[NSMutableDictionary dictionary] retain];
		mSourceUrl = [sourceUrl retain];
        mRegisteredResources = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void) dealloc
{
	[mHeartbeat invalidate];
	[mHeartbeat release];
	[mChronologicalResourceTypes release];
	[mProvider release];
	[mSourceUrl release];
    [mRegisteredResources release];
	[super dealloc];
}

- (Class)getRegisteredResourceClassWithName:(NSString*)resourceName
{
    return [mRegisteredResources objectForKey:resourceName];
}

- (void)resetToDefaultPollingFrequency
{
	NSUInteger defaultPollingFrequency = [OpenFeint getPollingFrequencyDefault];
	[self changePollingFrequency:defaultPollingFrequency];
}

- (void)changePollingFrequency:(NSTimeInterval)pollingFrequency
{
	[self stopPolling];
	
	if(pollingFrequency == 0.0f)
	{
		return;
	}
	
	mHeartbeat = [[OFTimerHeartbeat scheduledTimerWithInterval:pollingFrequency target:self selector:@selector(pollNow)] retain];
	OFLog(@"Polling every %f seconds", pollingFrequency);
}

- (void)stopPolling
{
	[mHeartbeat invalidate];
	[mHeartbeat release];
	mHeartbeat = nil;
	OFLog(@"Stopped polling");
}

- (void)registerResourceClass:(Class)resourceClassType;
{	
	if(![resourceClassType isSubclassOfClass:[OFResource class]])
	{
		NSAssert1(0, @"'%s' must derive from OFResource to be work with the Polling system.", class_getName(resourceClassType));
		return;
	}
	
	NSString* name = [resourceClassType performSelector:@selector(getResourceName)];
	NSString* notificationName = [resourceClassType performSelector:@selector(getResourceDiscoveredNotification)];
		
    [mRegisteredResources setObject:resourceClassType forKey:name];
	
	OFPollerResourceType* resourceType = [[[OFPollerResourceType alloc] initWithName:name andDiscoveryNotification:notificationName] autorelease];
	[mChronologicalResourceTypes setObject:resourceType forKey:resourceClassType];
}

- (void)clearCacheForResourceClass:(Class)resourceClassType
{
	OFPollerResourceType* resourceType = [mChronologicalResourceTypes objectForKey:resourceClassType];
	[resourceType markNewResourcesOld];
	[resourceType clearLastSeenId];
}

- (void)clearCacheAndForceLastSeenId:(long long)lastSeenId forResourceClass:(Class)resourceClassType
{
	OFPollerResourceType* resourceType = [mChronologicalResourceTypes objectForKey:resourceClassType];
	[resourceType markNewResourcesOld];
	[resourceType forceLastSeenId:lastSeenId];
}

- (void)_onPollComplete
{
	mInPoll = NO;
	if (mQueuedPoll)
	{
		mQueuedPoll = NO;
		[self pollNow];
	}
}

- (void)_onSucceededDownloading:(MPOAuthAPIRequestLoader*)request
{
  	OFPaginatedSeries* incomingResources = [OFResource resourcesFromXml:[OFXmlElement elementWithData:request.data] withMap:mRegisteredResources];
	
	NSMutableSet* incomingTypes = [NSMutableSet set];
	for(OFResource* currentResource in incomingResources.objects)
	{
		OFPollerResourceType* resourceType = [mChronologicalResourceTypes objectForKey:[currentResource class]];
		[resourceType addResource:currentResource];
		[incomingTypes addObject:resourceType];
	}

	for(OFPollerResourceType* resourceType in incomingTypes)
	{
		NSDictionary* resourcesDictionary = [NSDictionary dictionaryWithObject:resourceType.changedResources forKey:OFPollerNotificationKeyForResources];
		[[NSNotificationCenter defaultCenter] postNotificationName:resourceType.discoveryNotification object:nil userInfo:resourcesDictionary];
		[resourceType markNewResourcesOld];
	}
	[self _onPollComplete];
}

- (void)_onFailedDownloading
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OFPollingFailed" object:mSourceUrl userInfo:nil];
	[self _onPollComplete];
}

- (void)pollNow
{		
	if(![mProvider isAuthenticated])
	{
		return;
	}
	
	if (mInPoll)
	{
		mQueuedPoll = YES;
		return;
	}
	
	mQueuedPoll = NO;
	mInPoll = YES;
	
	OFLog(@"Polling Now");
	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	for(Class resourceClass in mChronologicalResourceTypes)
	{
		OFPollerResourceType* resourceType = [mChronologicalResourceTypes objectForKey:resourceClass];
        [params ioNSStringToKey:resourceType.idParameterName object:[[NSNumber numberWithLongLong:resourceType.lastSeenId] stringValue]];
	}
	
	[mProvider performAction:mSourceUrl
			  withParameters:params.getQueryParametersAsMPURLRequestParameters
			  withHttpMethod:@"GET"
       withSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onSucceededDownloading:)]
       withFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onFailedDownloading)]
//			     withSuccess:OFDelegate(self, @selector(_onSucceededDownloading:))
//				 withFailure:OFDelegate(self, @selector(_onFailedDownloading))
				withRequestType:OFActionRequestSilent
				  withNotice:nil];
}

- (NSTimeInterval)getPollingFrequency
{
	return mHeartbeat.timeInterval;
}

@end
