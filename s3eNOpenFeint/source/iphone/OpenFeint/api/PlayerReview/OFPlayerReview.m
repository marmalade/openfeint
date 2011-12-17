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
#import "OFPlayerReview.h"
#import "OFClientApplicationService.h"
#import "OFUser.h"
#import "OFDependencies.h"

@implementation OFPlayerReview

@synthesize user;
@synthesize favorite;
@synthesize review;

- (void)setUser:(OFUser*)value
{
	if (value != user)
	{
		OFSafeRelease(user);
		user = [value retain];
	}	
}

- (void)setfavorite:(NSString*)value
{
	favorite = [value boolValue];
}

- (void)setReview:(NSString*)value
{
	if (review != value)
	{
		OFSafeRelease(review);
		review = [value retain];
	}
}

+ (OFService*)getService;
{
	return [OFClientApplicationService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"client_application_user";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_player_review_discovered";
}

- (void) dealloc
{
	OFSafeRelease(user);
	OFSafeRelease(review);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setfavorite:)], @"favorite",
[OFResourceField fieldSetter:@selector(setReview:)], @"review",
        nil] retain];
    }
    return sDataDictionary;
}
@end
