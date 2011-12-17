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
#import "OFNewsletterSubscription.h"
#import "OFUserSettingService.h"
#import "OFUser.h"
#import "OFDependencies.h"

@implementation OFNewsletterSubscription

@synthesize user, developer;

- (void)setUser:(OFUser*)value
{ 
	if (value != user)
	{
		OFSafeRelease(user);
		user = [value retain];
	}
}

- (void)setDeveloper:(OFUser*)value
{ 
	if (value != developer)
	{
		OFSafeRelease(developer);
		developer = [value retain];
	}
}

+ (OFService*)getService;
{
	return [OFUserSettingService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"news_letter_subscription";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"news_letter_subscription_discovered";
}

- (void) dealloc
{
	OFSafeRelease(user);
	OFSafeRelease(developer);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
[OFResourceField nestedResourceSetter:@selector(setDeveloper:) getter:nil klass:[OFUser class]], @"developer",
        nil] retain];
    }
    return sDataDictionary;
}
@end
