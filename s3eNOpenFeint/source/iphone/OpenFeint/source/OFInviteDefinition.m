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
#import "OFInviteDefinition.h"
#import "OFInviteService.h"
#import "OFPaginatedSeries.h"
#import "OFImageView.h"
#import "OFImageCache.h"
#import "OpenFeint+Private.h"
#import "OFDependencies.h"

//Internalize the set functions.
#define setStringFunc(func, var) - (void)func:(NSString*)value \
								{ \
									OFSafeRelease(var); \
									var = [value retain]; \
								}

static id sharedDelegate = nil;

@interface OFInviteDefinition (Private)
+ (void)_getPrimaryInviteDefinitionSuccess:(OFPaginatedSeries*)resources;
+ (void)_getPrimaryInviteDefinitionFailure;
+ (void)_getInviteDefinitionSuccess:(OFPaginatedSeries*)resources;
+ (void)_getInviteDefinitionFailure;
@end

@implementation OFInviteDefinition

@synthesize clientApplicationName;
@synthesize clientApplicationID;
@synthesize inviteIdentifier;
@synthesize inviteIconURL;
@synthesize developerMessage;
@synthesize receiverNotification;
@synthesize senderNotification;
@synthesize senderIncentiveText;
@synthesize suggestedSenderMessage;

+ (void)setDelegate:(id<OFInviteDefinitionDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFInviteDefinition cancelPreviousPerformRequestsWithTarget:[OFInviteDefinition class]];
	}
}

+ (OFRequestHandle*)getPrimaryInviteDefinition
{
	OFRequestHandle* handle = nil;
//	handle = [OFInviteService getDefaultInviteDefinitionForApplication:OFDelegate(self, @selector(_getPrimaryInviteDefinitionSuccess:))
//															 onFailure:OFDelegate(self, @selector(_getPrimaryInviteDefinitionFailure))];
	handle = [OFInviteService getDefaultInviteDefinitionForApplicationInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getPrimaryInviteDefinitionSuccess:)] 
                                                             onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getPrimaryInviteDefinitionFailure)]];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFInviteDefinition class]];
	return handle;
}

+ (OFRequestHandle*)getInviteDefinition:(NSString*)inviteId
{
	OFRequestHandle* handle = nil;
	handle = [OFInviteService getInviteDefinition:inviteId 
                              onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getInviteDefinitionSuccess:)]
                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getInviteDefinitionFailure)]];
//										onSuccess:OFDelegate(self, @selector(_getInviteDefinitionSuccess:))
//										onFailure:OFDelegate(self, @selector(_getInviteDefinitionFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFInviteDefinition class]];
	return handle;
	
	
}

- (OFRequestHandle*)getInviteIcon
{    
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetInviteIcon:OFInviteDefinition:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetInviteIcon:OFInviteDefinition:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(didFailGetInviteIconOFInviteDefinition:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didFailGetInviteIconOFInviteDefinition:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:inviteIconURL forModule:[OFInviteDefinition class] onSuccess:success onFailure:failure];
	return handle;    
}

+ (void)_getPrimaryInviteDefinitionSuccess:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		OFInviteDefinition* inviteDef = [resources.objects objectAtIndex:0];
		if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetPrimaryInviteDefinition:)])
		{
			[sharedDelegate didGetPrimaryInviteDefinition:inviteDef];
		}
	}
	else
	{
		[self _getPrimaryInviteDefinitionFailure];
	}
}

+ (void)_getPrimaryInviteDefinitionFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetPrimaryInviteDefinition)])
	{
		[sharedDelegate didFailGetPrimaryInviteDefinition];
	}
}

+ (void)_getInviteDefinitionSuccess:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		OFInviteDefinition* inviteDef = [resources.objects objectAtIndex:0];
		if (sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetInviteDefinition:)])
		{
			[sharedDelegate didGetInviteDefinition:inviteDef];
		}
	}
	else
	{
		[self _getInviteDefinitionFailure];
	}
}

+ (void)_getInviteDefinitionFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetInviteDefinition)])
	{
		[sharedDelegate didFailGetInviteDefinition];
	}
}


+ (OFService*)getService;
{
	return [OFInviteService sharedInstance];
}

setStringFunc(setClientApplicationName, clientApplicationName)
setStringFunc(setClientApplicationID, clientApplicationID)
setStringFunc(setInviteIdentifier, inviteIdentifier)
setStringFunc(setInviteIconURL, inviteIconURL)
setStringFunc(setDeveloperMessage, developerMessage)
setStringFunc(setReceiverNotification, receiverNotification)
setStringFunc(setSenderNotification, senderNotification)
setStringFunc(setSenderIncentiveText, senderIncentiveText);
setStringFunc(setSuggestedSenderMessage, suggestedSenderMessage);


+ (NSString*)getResourceName
{
	return @"invite_definition";
}

- (void) dealloc
{
	OFSafeRelease(clientApplicationName);
	OFSafeRelease(clientApplicationID);
	OFSafeRelease(inviteIdentifier);
	OFSafeRelease(inviteIconURL);
	OFSafeRelease(developerMessage);
	OFSafeRelease(receiverNotification);
	OFSafeRelease(senderNotification);
	OFSafeRelease(senderIncentiveText);
	OFSafeRelease(suggestedSenderMessage);
	[super dealloc];
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField fieldSetter:@selector(setClientApplicationName:) getter:@selector(clientApplicationName)], @"client_application_name",
[OFResourceField fieldSetter:@selector(setClientApplicationID:) getter:@selector(clientApplicationID)], @"client_application_id",
[OFResourceField fieldSetter:@selector(setInviteIdentifier:) getter:@selector(inviteIdentifier)], @"invite_identifier",
[OFResourceField fieldSetter:@selector(setInviteIconURL:) getter:@selector(inviteIconURL)], @"invite_icon_url",
[OFResourceField fieldSetter:@selector(setDeveloperMessage:) getter:@selector(developerMessage)], @"developer_message",
[OFResourceField fieldSetter:@selector(setReceiverNotification:) getter:@selector(receiverNotification)], @"receiver_notification",
[OFResourceField fieldSetter:@selector(setSenderNotification:) getter:@selector(senderNotification)], @"sender_notification",
[OFResourceField fieldSetter:@selector(setSenderIncentiveText:) getter:@selector(senderIncentiveText)], @"sender_incentive_text",
[OFResourceField fieldSetter:@selector(setSuggestedSenderMessage:) getter:@selector(suggestedSenderMessage)], @"suggested_sender_message",
        nil] retain];
    }
    return sDataDictionary;
}
@end
