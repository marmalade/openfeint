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
#import "OFForumPost.h"
#import "OFForumService.h"
#import "OFUser.h"
#import "OFDependencies.h"
#import "NSDateFormatter+OpenFeint.h"

@implementation OFForumPost

@synthesize author, body, date, discussionId, isDiscussionConversation;

#pragma mark Boilerplate

- (void)dealloc
{
	OFSafeRelease(author);
	OFSafeRelease(body);
	OFSafeRelease(date);
	self.discussionId = nil;
	
	[super dealloc];
}

#pragma mark XML Data Field Methods

- (void)setAuthor:(OFUser *)user
{
	OFSafeRelease(author);
	author = [user retain];
}

- (void)setBody:(NSString*)value
{
	OFSafeRelease(body);
	body = [value retain];
}

- (void)setDateFromXml:(NSString*)value
{
	OFSafeRelease(date);
	date = [[[NSDateFormatter railsFormatter] dateFromString:value] retain];
}

- (void)setIsDiscussionConversation:(NSString*)value
{
	isDiscussionConversation = [value boolValue];
}

- (NSString*)dateToXml
{
	return [[NSDateFormatter railsFormatter] stringFromDate:self.date];
}

#pragma mark OFResource

+ (OFService*)getService
{
	return [OFForumService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"post";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"post_discovered";
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setAuthor:) getter:@selector(author) klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setBody:) getter:@selector(body)], @"body",
[OFResourceField fieldSetter:@selector(setDateFromXml:) getter:@selector(dateToXml)], @"created_at",
[OFResourceField fieldSetter:@selector(setDiscussionId:) getter:@selector(discussionId)], @"discussion_id",
[OFResourceField fieldSetter:@selector(setIsDiscussionConversation:)], @"is_discussion_conversation",
        nil] retain];
    }
    return sDataDictionary;
}
@end
