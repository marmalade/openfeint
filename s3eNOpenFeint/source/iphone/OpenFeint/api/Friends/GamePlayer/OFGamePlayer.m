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
#import "OFGamePlayer.h"
#import "OFProfileService.h"
#import "OFUser.h"
#import "OFDependencies.h"

@implementation OFGamePlayer

@synthesize user, applicationId, applicationGamerscore, isFavorite;

- (void)setIsFavorite:(NSString*)value
{
	isFavorite = [value boolValue];
}

- (void)setApplicationId:(NSString*)value
{
	applicationId = [value retain];
}

- (void)setApplicationGamerscore:(NSString*)value
{
	applicationGamerscore = [value intValue];
}

- (void)setUser:(OFResource*)value
{
	user = (OFUser*)[value retain];
}

+ (OFService*)getService;
{
	return [OFProfileService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"game_player";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

- (void) dealloc
{
	OFSafeRelease(user);
	OFSafeRelease(applicationId);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setUser:) getter:nil klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setApplicationId:)], @"app_id",
[OFResourceField fieldSetter:@selector(setApplicationGamerscore:)], @"app_gamerscore",
[OFResourceField fieldSetter:@selector(setIsFavorite:)], @"favorite",
        nil] retain];
    }
    return sDataDictionary;
}
@end
