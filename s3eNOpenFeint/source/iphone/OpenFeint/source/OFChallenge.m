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
#import "OFChallenge.h"
#import "OFChallengeService.h"
#import "OFChallengeDefinition.h"
#import "OFUser.h"
#import "OFDependencies.h"

static id sharedDelegate = nil;

@interface OFChallenge (Private)
- (void)setChallengeDefinition:(OFChallengeDefinition*)value;
- (void)setChallengeDescription:(NSString*)value;
- (void)setUserMessage:(NSString*)value;
- (void)setHiddenText:(NSString*)value;
- (void)_sendChallengeSuccess;
- (void)_sendChallengeFailure;
- (void)_downloadChallengeDataSuccess:(NSData*)data;
- (void)_downloadChallengeDataFailure;
@end

@implementation OFChallenge

@synthesize challengeDefinition, challengeDescription, challenger, challengeDataUrl, hiddenText, userMessage, challengeData;

+ (void)setDelegate:(id<OFChallengeSendDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFChallenge class]];
	}
}

- (OFChallenge*)initWithDefinition:(OFChallengeDefinition*)definition challengeDescription:(NSString*)text challengeData:(NSData*)data
{
	self = [super init];
	if(self)
	{
		challengeDefinition = [definition retain];
		challengeDescription = [text retain];
		challengeData = [data retain];
	}
	return self;
}

- (void)displayAndSendChallenge
{
	[OFChallengeService displaySendChallengeModal:self.challengeDefinition.resourceId
									challengeText:self.challengeDescription 
									challengeData:self.challengeData];
}

- (OFRequestHandle*)sendChallenge:(OFChallengeDefinition*)challengeDefinition
						  toUsers:(NSArray*)userIds 
			inResponseToChallenge:(OFChallenge*)instigatingChallenge
{
	OFRequestHandle* handle = nil;
	handle = [OFChallengeService sendChallenge:self.challengeDefinition.resourceId
								 challengeText:self.challengeDescription
								 challengeData:self.challengeData
								   userMessage:self.userMessage
									hiddenText:self.hiddenText
									   toUsers:userIds
						 inResponseToChallenge:instigatingChallenge.resourceId
                           onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_sendChallengeSuccess)]
                           onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_sendChallengeFailure)]];
//									 onSuccess:OFDelegate(self, @selector(_sendChallengeSuccess))
//									 onFailure:OFDelegate(self, @selector(_sendChallengeFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFChallenge class]];
	return handle;
}

- (OFRequestHandle*)downloadChallengeData
{
	OFRequestHandle* handle = nil;
	handle = [OFChallengeService downloadChallengeData:self.challengeDataUrl
                                   onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadChallengeDataSuccess:)]
                                   onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadChallengeDataFailure)]];
//											 onSuccess:OFDelegate(self, @selector(_downloadChallengeDataSuccess:))
//											 onFailure:OFDelegate(self, @selector(_downloadChallengeDataFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFChallenge class]];
	return handle;
}

- (void)_sendChallengeSuccess
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didSendChallenge:)])
	{
		[sharedDelegate didSendChallenge:self];
	}
}

- (void)_sendChallengeFailure
{
	if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailSendChallenge:)])
	{
		[sharedDelegate didFailSendChallenge:self];
	}
}

- (void)_downloadChallengeDataSuccess:(NSData*)data
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadChallengeData:OFChallenge:)])
	{
		[sharedDelegate didDownloadChallengeData:data OFChallenge:self];
	}
}

- (void)_downloadChallengeDataFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadChallengeDataOFChallenge:)])
	{
		[sharedDelegate didFailDownloadChallengeDataOFChallenge:self];
	}
}

- (void)setChallengeDefinition:(OFChallengeDefinition*)value
{
	OFSafeRelease(challengeDefinition);
	challengeDefinition = [value retain];
}

- (void)setChallengeDescription:(NSString*)value
{
	OFSafeRelease(challengeDescription);
	challengeDescription = [value retain];
}

- (void)setUserMessage:(NSString*)value
{
	OFSafeRelease(userMessage);
	userMessage = [value retain];
}

-(void)setHiddenText:(NSString*)value
{
	OFSafeRelease(hiddenText);
	hiddenText = [value retain];
}

- (OFChallengeDefinition*)getChallengeDefinition
{
	return challengeDefinition;
}

- (void)setDataUrl:(NSString*)value
{
	OFSafeRelease(challengeDataUrl);
	challengeDataUrl = [value retain];
}


+ (OFService*)getService;
{
	return [OFChallengeService sharedInstance];
}

- (void)setChallenger:(OFUser*)value
{
	OFSafeRelease(challenger);
	challenger = [value retain];
}

- (OFUser*)getChallenger
{
	return challenger;
}


+ (NSString*)getResourceName
{
	return @"challenge";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return @"openfeint_challenge_discovered";
}

- (BOOL)usesChallengeData
{
	return	challengeDataUrl && 
	![challengeDataUrl isEqualToString:@""] &&
	![challengeDataUrl isEqualToString:@"/empty.blob"];
}

- (void) dealloc
{
	OFSafeRelease(challengeData);
	OFSafeRelease(challengeDefinition);
	OFSafeRelease(challenger);
	OFSafeRelease(challengeDescription);
	OFSafeRelease(userMessage);
	OFSafeRelease(challengeDataUrl);
	OFSafeRelease(hiddenText);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setChallengeDefinition:) getter:@selector(getChallengeDefinition) klass:[OFChallengeDefinition class]], @"challenge_definition",
[OFResourceField nestedResourceSetter:@selector(setChallenger:) getter:@selector(getChallenger) klass:[OFUser class]], @"user",
[OFResourceField fieldSetter:@selector(setChallengeDescription:) getter:@selector(challengeDescription)], @"description",
[OFResourceField fieldSetter:@selector(setHiddenText:) getter:@selector(hiddenText)], @"hidden_text",
[OFResourceField fieldSetter:@selector(setUserMessage:) getter:@selector(userMessage)], @"user_message",
[OFResourceField fieldSetter:@selector(setDataUrl:) getter:@selector(challengeDataUrl)], @"user_data_url",
        nil] retain];
    }
    return sDataDictionary;
}
@end
