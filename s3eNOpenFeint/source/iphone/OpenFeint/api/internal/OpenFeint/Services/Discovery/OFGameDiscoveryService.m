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

#import "OFGameDiscoveryService.h"
#import "OFGameDiscoveryCategory.h"
#import "OFGameDiscoveryNewsItem.h"
#import "OFService+Private.h"
#import "OFPlayedGame.h"
#import "OFQueryStringWriter.h"
#import "OFGameDiscoveryImageHyperlink.h"
#import "OpenFeint+Private.h"
#import "OFResource+ObjC.h"
#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFGameDiscoveryService);

@implementation OFGameDiscoveryService

OPENFEINT_DEFINE_SERVICE(OFGameDiscoveryService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFGameDiscoveryImageHyperlink class] forKey:[OFGameDiscoveryImageHyperlink getResourceName]];
	[namedResourceMap setObject:[OFGameDiscoveryNewsItem class] forKey:[OFGameDiscoveryNewsItem getResourceName]];
	[namedResourceMap setObject:[OFGameDiscoveryCategory class] forKey:[OFGameDiscoveryCategory getResourceName]];
	[namedResourceMap setObject:[OFPlayedGame class] forKey:[OFPlayedGame getResourceName]];
}

+ (void)getGameDiscoveryCategoriesOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[self getDiscoveryPageNamed:nil withPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

+ (OFRequestHandle*)getIndexOnSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure
{
	[self getGameDiscoveryCategoriesOnSuccessInvocation:onSuccess onFailureInvocation:onFailure];
    return nil;
}

+ (OFRequestHandle*)getDiscoveryPageNamed:(NSString*)targetDiscoveryPageName withPage:(NSInteger)oneBasedPageNumber onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioIntToKey:@"page" value:oneBasedPageNumber];
	
	NSString* orientation;
    if ([OpenFeint isLargeScreen]) {
        orientation = @"ipad";
    } else {
        orientation = [OpenFeint isInLandscapeMode] ? @"landscape" : @"portrait";
    }
	[params ioNSStringToKey:@"orientation" object:orientation];
	
	NSString* actionName = nil;
	if(targetDiscoveryPageName == nil)
	{
		actionName = @"game_discovery_categories";
	}
	else
	{
		actionName = [NSString stringWithFormat:@"game_discovery_categories/%@.xml", targetDiscoveryPageName];
	}
	[params ioNSStringToKey:@"client_application_id" object:[OpenFeint clientApplicationId]];
	
	return [[self sharedInstance] 
		 _performAction:actionName
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withHttpMethod:@"GET"
            withSuccessInvocation:success
            withFailureInvocation:failure
            withRequestType:OFActionRequestSilent
		 withNotice:nil
         requiringAuthentication:NO];
}

+ (void)getNowPlayingFeaturedPlacementInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	[self getDiscoveryPageNamed:@"now_playing_featured_placement" withPage:1 onSuccessInvocation:success onFailureInvocation:failure];
}

@end
