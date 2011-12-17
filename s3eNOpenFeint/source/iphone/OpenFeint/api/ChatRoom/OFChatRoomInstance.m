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

#import "OFResourceField.h"
#import "OFChatRoomInstance.h"
#import "OFChatRoomInstanceService.h"
#import "OFChatRoomDefinition.h"

@implementation OFChatRoomInstance

@synthesize roomName;
@synthesize roomType;
@synthesize numUsersInRoom;
@synthesize maxNumUsersInRoom; 

- (void)setRoomName:(NSString*)value
{
	roomName = [value retain];
}

- (void)setRoomType:(NSString*)value
{
	roomType = [value retain];
}

- (void)setNumUsersInRoom:(NSString*)value
{
	numUsersInRoom = [value intValue];
}

- (void)setMaxNumUsersInRoom:(NSString*)value
{
	maxNumUsersInRoom = [value intValue];
}

+ (OFService*)getService;
{
	return [OFChatRoomInstanceService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"chat_room_instance";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_chat_room_instance_discovered";
}

- (BOOL)isDeveloperRoom
{
	return [roomType isEqualToString:[OFChatRoomDefinition getDeveloperRoomTypeId]];
}

- (BOOL)isGlobalRoom
{
	return [roomType isEqualToString:[OFChatRoomDefinition getGlobalRoomTypeId]];
}

- (BOOL)isApplicationRoom
{
	return [roomType isEqualToString:[OFChatRoomDefinition getApplicationRoomTypeId]];
}

- (void) dealloc
{
	[roomName release];
	[roomType release];
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setRoomName:)], @"room_name",
[OFResourceField fieldSetter:@selector(setNumUsersInRoom:)], @"num_users_in_room",
[OFResourceField fieldSetter:@selector(setMaxNumUsersInRoom:)], @"max_num_users_in_room",
[OFResourceField fieldSetter:@selector(setRoomType:)], @"room_type",
        nil] retain];
    }
    return sDataDictionary;
}
@end
