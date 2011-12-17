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
#import "OFForumThread.h"
#import "OFForumService.h"
#import "OFUser.h"

#import "NSDateFormatter+OpenFeint.h"
#import "OFDependencies.h"

@implementation OFForumThread

@synthesize title, lastPostAuthor, date, postCount, isLocked, isSticky, isSubscribed;

#pragma mark Boilerplate

- (void)dealloc
{
	self.title = nil;
	self.lastPostAuthor = nil;
	self.date = nil;
	[super dealloc];
}

#pragma mark XML Data Field Methods

- (void)setTitle:(NSString*)value
{
	OFSafeRelease(title);
	title = [value retain];
}

- (void)setDateFromString:(NSString*)value
{
	self.date = [[NSDateFormatter railsFormatter] dateFromString:value];
}

- (NSString*)dateAsString
{
	return [[NSDateFormatter railsFormatter] stringFromDate:self.date];
}

- (void)setLockedFromString:(NSString*)value
{
	isLocked = [value boolValue];
}

- (NSString*)lockedAsString
{
	return isLocked ? @"true" : @"false";
}

- (void)setPostCountFromString:(NSString*)value
{
	postCount = [value intValue];
}

- (NSString*)postCountAsString
{
	return [NSString stringWithFormat:@"%d", postCount];
}

- (void)setStickyFromString:(NSString*)value
{
	isSticky = [value boolValue];
}

- (NSString*)stickyAsString
{
	return isSticky ? @"true" : @"false";
}

- (void)setSubscribedFromString:(NSString*)value
{
	isSubscribed = [value boolValue];
}

- (NSString*)subscribedAsString
{
	return isSubscribed ? @"true" : @"false";
}

#pragma mark OFResource

+ (OFService*)getService
{
	return [OFForumService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"discussion";
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
[OFResourceField nestedResourceSetter:@selector(setLastPostAuthor:) getter:@selector(lastPostAuthor) klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setTitle:) getter:@selector(title)], @"subject",
[OFResourceField fieldSetter:@selector(setDateFromString:) getter:@selector(dateAsString)], @"updated_at",
[OFResourceField fieldSetter:@selector(setLockedFromString:) getter:@selector(lockedAsString)], @"locked",
[OFResourceField fieldSetter:@selector(setPostCountFromString:) getter:@selector(postCountAsString)], @"posts_count",
[OFResourceField fieldSetter:@selector(setStickyFromString:) getter:@selector(stickyAsString)], @"sticky",
[OFResourceField fieldSetter:@selector(setSubscribedFromString:) getter:@selector(subscribedAsString)], @"subscribed",
        nil] retain];
    }
    return sDataDictionary;
}
@end
