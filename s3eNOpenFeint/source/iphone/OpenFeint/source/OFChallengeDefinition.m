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
#import "OFChallengeDefinition.h"
#import "OFChallengeDefinitionService.h"
#import "OFPaginatedSeries.h"
#import "OFImageView.h"
#import "OFImageCache.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

static id sharedDelegate = nil;

@interface OFChallengeDefinition (Private)
+ (void)_downloadAllChallengeDefinitionsSuccess:(OFPaginatedSeries*)loadedChallenges;
+ (void)_downloadAllChallengeDefinitionsFail;
+ (void)_downloadChallengeDefinitionWithIdSuccess:(OFPaginatedSeries*)resources;
+ (void)_downloadChallengeDefinitionWithIdFail;
@end

@implementation OFChallengeDefinition

@synthesize title, iconUrl, multiAttempt, clientApplicationId;

+ (void)setDelegate:(id<OFChallengeDefinitionDelegate>)delegate;
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFChallengeDefinition class]];
	}
}

+ (OFRequestHandle*)downloadAllChallengeDefinitions
{
	OFRequestHandle* handle = nil;
//	handle = [OFChallengeDefinitionService getIndexOnSuccess:OFDelegate(self, @selector(_downloadAllChallengeDefinitionsSuccess:))
//												   onFailure:OFDelegate(self, @selector(_downloadAllChallengeDefinitionsFail))];
	handle = [OFChallengeDefinitionService getIndexOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadAllChallengeDefinitionsSuccess:)]
                                                   onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadAllChallengeDefinitionsFail)]];
              
	[OFRequestHandlesForModule addHandle:handle forModule:[OFChallengeDefinition class]];
	return handle;
	
}

+ (OFRequestHandle*)downloadChallengeDefinitionWithId:(NSString*)challengeDefinitionId
{
	OFRequestHandle* handle = nil;
	handle = [OFChallengeDefinitionService getChallengeDefinitionWithId:challengeDefinitionId
                                                    onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadChallengeDefinitionWithIdSuccess:)]
                                                    onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadChallengeDefinitionWithIdFail)]];
//															  onSuccess:OFDelegate(self, @selector(_downloadChallengeDefinitionWithIdSuccess:))
//															  onFailure:OFDelegate(self, @selector(_downloadChallengeDefinitionWithIdFail))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFChallengeDefinition class]];
	return handle;
}

- (OFRequestHandle*)getIcon
{
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetIcon:OFChallengeDefintion:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetIcon:OFChallengeDefintion:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(getFailGetIconOFChallengeDefinition:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(getFailGetIconOFChallengeDefinition:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:iconUrl forModule:[OFChallengeDefinition class] onSuccess:success onFailure:failure];
	return handle;
}

+ (void)_downloadAllChallengeDefinitionsSuccess:(OFPaginatedSeries*)loadedChallenges
{
	NSArray* challengeDefinitions = [[[NSArray alloc] initWithArray:loadedChallenges.objects] autorelease];

	if ([challengeDefinitions count] > 0)
	{
		if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadAllChallengeDefinitions:)])
		{
			[sharedDelegate didDownloadAllChallengeDefinitions:challengeDefinitions];
		}
	}
	else
	{
		[self _downloadAllChallengeDefinitionsFail];
	}

}

+ (void)_downloadAllChallengeDefinitionsFail
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadChallengeDefinitions)])
	{
		[sharedDelegate didFailDownloadChallengeDefinitions];
	}
}

+ (void)_downloadChallengeDefinitionWithIdSuccess:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		OFChallengeDefinition* challengeDefinition = [resources.objects objectAtIndex:0];
		if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadChallengeDefinition:)])
		{
			[sharedDelegate didDownloadChallengeDefinition:challengeDefinition];
		}
	}
	else
	{
		[self _downloadChallengeDefinitionWithIdFail];
	}
}

+ (void)_downloadChallengeDefinitionWithIdFail
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadChallengeDefinition)])
	{
		[sharedDelegate didFailDownloadChallengeDefinition];
	}
}


- (void)setTitle:(NSString*)value
{
	OFSafeRelease(title);
	title = [value retain];
}

- (void)setClientApplicationId:(NSString*)value
{
	if (clientApplicationId != value)
	{
		OFSafeRelease(clientApplicationId);
		clientApplicationId = [value retain];
	}
}

- (void)setIconUrl:(NSString*)value
{
	OFSafeRelease(iconUrl);
	iconUrl = [value retain];
}

- (void)setMultiAttempt:(NSString*)value
{
	multiAttempt = [value boolValue];
}

- (NSString*)getMultiAttemptAsString
{
	return [NSString stringWithFormat:@"%u", (uint)multiAttempt];
}

+ (OFService*)getService;
{
	return [OFChallengeDefinitionService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"challenge_definition";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_challenge_definition_discovered";
}

- (void) dealloc
{
	OFSafeRelease(title);
	OFSafeRelease(clientApplicationId);
	OFSafeRelease(iconUrl);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setTitle:) getter:@selector(title)], @"name",
[OFResourceField fieldSetter:@selector(setClientApplicationId:) getter:@selector(clientApplicationId)], @"client_application_id",
[OFResourceField fieldSetter:@selector(setIconUrl:) getter:@selector(iconUrl)], @"image_url",
[OFResourceField fieldSetter:@selector(setMultiAttempt:) getter:@selector(getMultiAttemptAsString)], @"multi_attempt",
        nil] retain];
    }
    return sDataDictionary;
}
@end
