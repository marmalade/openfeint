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

#import "OFChatRoomDefinitionService.h"

#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFChatRoomDefinition.h"
#import "OFChatRoomInstance.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFChatRoomDefinitionService);

@implementation OFChatRoomDefinitionService

OPENFEINT_DEFINE_SERVICE(OFChatRoomDefinitionService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFChatRoomDefinition class] forKey:[OFChatRoomDefinition getResourceName]];
	[namedResourceMap setObject:[OFChatRoomInstance class] forKey:[OFChatRoomInstance getResourceName]];
}

+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFChatRoomDefinitionService getPage:1 includeGlobalRooms:YES includeDeveloperRooms:YES includeApplicationRooms:YES includeLastVisitedRoom:YES 
                            onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex 
          includeGlobalRooms:(BOOL)includeGlobalRooms 
       includeDeveloperRooms:(BOOL)includeDeveloperRooms 
     includeApplicationRooms:(BOOL)includeApplicationRooms 
      includeLastVisitedRoom:(BOOL)includeLastVisitedRoom
         onSuccessInvocation:(OFInvocation*)_onSuccess
         onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioBoolToKey:@"include_global_rooms" value:includeGlobalRooms];
	[params ioBoolToKey:@"include_application_rooms" value:includeApplicationRooms];
	[params ioBoolToKey:@"include_developer_rooms" value:includeDeveloperRooms];
	[params ioBoolToKey:@"include_last_visited_room" value:includeLastVisitedRoom];
	
	return [[self sharedInstance] 
	 getAction:@"chat_room_definitions.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Chat Rooms")]];
}

@end
