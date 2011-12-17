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
#import "OFSubscription.h"
#import "OFSubscriptionService+Private.h"
#import "OFUser.h"
#import "OFConversation.h"
#import "OFForumThread.h"

#import "NSDateFormatter+OpenFeint.h"

static NSString* sStringForType[kOFSubscription_Count] = 
	{
		@"Forum",
		@"Conversation"
	};

@implementation OFSubscription

@synthesize type, discussionId, title, summary, lastActivity, lastViewed, unreadCount, topicId, otherUser, discussion, conversation;

#pragma mark Boilerplate

- (void)dealloc
{
	self.discussionId = nil;
	self.title = nil;
	self.summary = nil;
	self.lastActivity = nil;
	self.lastViewed = nil;
	self.topicId = nil;
	self.otherUser = nil;
    self.discussion = nil;
    self.conversation = nil;
	[super dealloc];
}

#pragma mark Public Methods

- (BOOL)isForumThread
{
	return type == kOFSubscription_Forum;
}

- (BOOL)isConversation
{
	return type == kOFSubscription_Conversation;
}

#pragma mark XML Data Field Methods

- (void)setLastActivityFromString:(NSString*)value
{
	self.lastActivity = [[NSDateFormatter railsFormatter] dateFromString:value];
}

- (NSString*)lastActivityAsString
{
	return [[NSDateFormatter railsFormatter] stringFromDate:self.lastActivity];
}

- (void)setLastViewedFromString:(NSString*)value
{
	self.lastViewed = [[NSDateFormatter railsFormatter] dateFromString:value];
}

- (NSString*)lastViewedAsString
{
	return [[NSDateFormatter railsFormatter] stringFromDate:self.lastViewed];
}

- (void)setUnreadCountFromString:(NSString*)value
{
	unreadCount = [value intValue];
}

- (NSString*)unreadCountAsString
{
	return [NSString stringWithFormat:@"%d", unreadCount];
}

- (void)setTypeFromString:(NSString*)value
{
	for (int i = 0; i < kOFSubscription_Count; ++i)
	{
		if ([sStringForType[i] isEqualToString:value])
		{
			type = (OFSubscriptionType)i;
			break;
		}
	}
}

- (NSString*)typeFromString
{
	return sStringForType[type];
}


#pragma mark OFResource

+ (OFService*)getService
{
	return [OFSubscriptionService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"subscription";
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
[OFResourceField nestedResourceSetter:@selector(setOtherUser:) getter:@selector(otherUser) klass:[OFUser class]], @"user",
[OFResourceField nestedResourceSetter:@selector(setDiscussion:) getter:@selector(discussion) klass:[OFForumThread class]], @"discussion",
[OFResourceField nestedResourceSetter:@selector(setConversation:) getter:@selector(conversation) klass:[OFConversation class]], @"conversation",
[OFResourceField fieldSetter:@selector(setDiscussionId:) getter:@selector(discussionId)], @"discussion_id",
[OFResourceField fieldSetter:@selector(setSummary:) getter:@selector(summary)], @"summary",
[OFResourceField fieldSetter:@selector(setTitle:) getter:@selector(title)], @"title",
[OFResourceField fieldSetter:@selector(setLastActivityFromString:) getter:@selector(lastActivityAsString)], @"updated_at",
[OFResourceField fieldSetter:@selector(setLastViewedFromString:) getter:@selector(lastViewedAsString)], @"last_viewed_at",
[OFResourceField fieldSetter:@selector(setUnreadCountFromString:) getter:@selector(unreadCountAsString)], @"unread_count",
[OFResourceField fieldSetter:@selector(setLockedFromString:) getter:@selector(lockedAsString)], @"locked",
[OFResourceField fieldSetter:@selector(setTopicId:) getter:@selector(topicId)], @"topic_id",
[OFResourceField fieldSetter:@selector(setTypeFromString:) getter:@selector(typeFromString)], @"discussion_type",
        nil] retain];
    }
    return sDataDictionary;
}
@end
