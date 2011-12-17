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

#import "OFChatRoomInstanceService.h"
#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFChatRoomDefinition.h"
#import "OFChatRoomInstance.h"
#import "OFChatMessageService.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFChatRoomInstanceService);

@implementation OFChatRoomInstanceService

@synthesize lastRoom = mLastRoom;
@synthesize roomJoining = mRoomJoining;
@synthesize rejoiningRoom = mRejoiningRoom;

OPENFEINT_DEFINE_SERVICE(OFChatRoomInstanceService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFChatRoomInstance class] forKey:[OFChatRoomInstance getResourceName]];
}

- (CFAbsoluteTime)getTimeSinceLastRoomUpdated
{
	return CFAbsoluteTimeGetCurrent() - mLastUpdateOfLastRoom;
}

+ (void) getPage:(NSInteger)pageIndex forChatRoomDefinition:(OFChatRoomDefinition*)roomDefinition 
        onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"chat_room_definition_id" object:roomDefinition.resourceId];
	[params ioIntToKey:@"page" value:pageIndex];
	
	
	[[self sharedInstance] 
	 getAction:@"chat_room_instances.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Room Instances")]];
}

+ (void) attemptToJoinRoom:(OFChatRoomInstance*)roomToJoin 
				 rejoining:(BOOL)rejoining  
       onSuccessInvocation:(OFInvocation*)_onSuccess 
       onFailureInvocation:(OFInvocation*)_onFailure
{
//	OFDelegate chainedSuccessDelegate([self sharedInstance], @selector(_onJoinedChatRoom:nextCall:), _onSuccess);
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"chat_room_instance_id" object:roomToJoin.resourceId];
	
	[self sharedInstance].roomJoining = roomToJoin;
	[self sharedInstance].rejoiningRoom = rejoining;
	
	[[self sharedInstance] 
	 getAction:@"chat_room_instances/join"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(_onJoinedChatRoom:nextCall:) chained:_onSuccess]
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Joined Chat Room")]];
}

+ (void) loadLastRoomJoinedInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{

	CFTimeInterval timeSinceUpdated = [[self sharedInstance]getTimeSinceLastRoomUpdated];
	if (timeSinceUpdated < 10.f)
	{
		[_onSuccess invokeWith:self.sharedInstance.lastRoom];
	}
	else
	{
//		OFDelegate chainedSuccessDelegate([self sharedInstance], @selector(_onLoadedLastJoinedChatRoom:nextCall:), _onSuccess);
		
		[[self sharedInstance] 
		 getAction:@"chat_room_instances/show"
         withParameterArray:nil
         withSuccessInvocation:[OFInvocation invocationForTarget:self.sharedInstance selector:@selector(_onLoadedLastJoinedChatRoom:nextCall:) chained:_onSuccess]
         withFailureInvocation:_onFailure
		 withRequestType:OFActionRequestSilent
		 withNotice:nil];
	}
}

+ (OFChatRoomInstance*) getCachedLastRoomJoined
{
	return [self sharedInstance].lastRoom;
}

- (void)_onJoinedChatRoom:(NSObject*)param nextCall:(OFInvocation*)nextCall
{
	if (!self.rejoiningRoom)
	{
		[OFChatMessageService clearCacheAndPollNow];
	}
	self.lastRoom = self.roomJoining;
	self.roomJoining = nil;
	self.rejoiningRoom = NO;
	mLastUpdateOfLastRoom = CFAbsoluteTimeGetCurrent();
	[nextCall invokeWith:param];
}

- (void)_onLoadedLastJoinedChatRoom:(NSArray*)roomArray nextCall:(OFInvocation*)nextCall
{
	mLastUpdateOfLastRoom = CFAbsoluteTimeGetCurrent();
	if ([roomArray count] == 1)
	{
		self.lastRoom = [roomArray objectAtIndex:0];
	}
	else
	{
		self.lastRoom = nil;
	}
	[nextCall invokeWith:self.lastRoom];
}




@end
