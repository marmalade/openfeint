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
#import "OFChatMessage.h"
#import "OFChatMessageService.h"
#import "OFChatMessageService.h"
#import "OFUser.h"
#import "OFDependencies.h"

@implementation OFChatMessage

@synthesize message;
@synthesize date;
@synthesize playerCurrentGameIconUrl;
@synthesize doesLocalPlayerOwnGame;
@synthesize user;

- (void)setMessage:(NSString*)value
{
	OFSafeRelease(message);
	message = [value retain];
}

- (void)setDate:(NSString*)value
{
	OFSafeRelease(date);
	date = [value retain];
}

- (void)setPlayerCurrentGameIconUrl:(NSString*)value
{
	OFSafeRelease(playerCurrentGameIconUrl);
	playerCurrentGameIconUrl = [value retain];
}

- (void)setDoesLocalPlayerOwnGame:(NSString*)value
{
	doesLocalPlayerOwnGame = [value boolValue];
}

- (void)setUser:(OFUser*)value
{
	OFSafeRelease(user);
	user = [value retain];
}

+ (OFService*)getService;
{
	return [OFChatMessageService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"chat_message";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_chat_message_discovered";
}

- (void) dealloc
{
	OFSafeRelease(message);
	OFSafeRelease(date);
	OFSafeRelease(playerCurrentGameIconUrl);
	OFSafeRelease(user);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setMessage:)], @"message",
[OFResourceField fieldSetter:@selector(setDate:)], @"date",
[OFResourceField fieldSetter:@selector(setPlayerCurrentGameIconUrl:)], @"player_current_game_icon_url",
[OFResourceField fieldSetter:@selector(setDoesLocalPlayerOwnGame:)], @"local_user_owns_application",
        nil] retain];
    }
    return sDataDictionary;
}
@end
