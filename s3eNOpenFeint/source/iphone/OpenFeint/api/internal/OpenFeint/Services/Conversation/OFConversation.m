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
#import "OFConversation.h"
#import "OFConversationService+Private.h"
#import "OFUser.h"

#import "NSDateFormatter+OpenFeint.h"

@implementation OFConversation

@synthesize subject, otherUser, lastMessageAt, messageCount;

#pragma mark Boilerplate

- (void)dealloc
{
	self.subject = nil;
	self.otherUser = nil;
	self.lastMessageAt = nil;
	[super dealloc];
}

#pragma mark XML Data Field Methods

- (void)setLastMessageAtFromString:(NSString*)value
{
	self.lastMessageAt = [[NSDateFormatter railsFormatter] dateFromString:value];
}

- (NSString*)lastMessageAtAsString
{
	return [[NSDateFormatter railsFormatter] stringFromDate:self.lastMessageAt];
}

- (void)setMessageCountFromString:(NSString*)value
{
	messageCount = [value intValue];
}

- (NSString*)messageCountAsString
{
	return [NSString stringWithFormat:@"%d", messageCount];
}

- (void)setUser:(OFUser*)user
{
	if (![user isLocalUser])
	{
		self.otherUser = user;
	}
}

#pragma mark OFResource

+ (OFService*)getService
{
	return [OFConversationService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"conversation";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:@selector(otherUser) klass:[OFUser class]], @"user",
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:@selector(otherUser) klass:[OFUser class]], @"other_user",
[OFResourceField fieldSetter:@selector(setSubject:) getter:@selector(subject)], @"subject",
[OFResourceField fieldSetter:@selector(setLastMessageAtFromString:) getter:@selector(lastMessageAtAsString)], @"updated_at",
[OFResourceField fieldSetter:@selector(setMessageCountFromString:) getter:@selector(messageCountAsString)], @"posts_count",
        nil] retain];
    }
    return sDataDictionary;
}
@end
