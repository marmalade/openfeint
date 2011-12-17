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
#import "OFInvite.h"
#import "OFInviteDefinition.h"
#import "OFUser.h"
#import "OFInviteService.h"
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

@interface OFInvite (Private)
- (void)_sendInviteSuccess;
- (void)_sendInviteFailure;
@end

@implementation OFInvite

@synthesize senderUser;
@synthesize receiverUser;
@synthesize clientApplicationName;
@synthesize clientApplicationID;
@synthesize inviteIdentifier;
@synthesize inviteIconURL;
@synthesize developerMessage;
@synthesize receiverNotification;
@synthesize senderNotification;
@synthesize userMessage;
@synthesize state;

+ (void)setDelegate:(id<OFInviteSendDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFInvite class]];
	}
}

- (OFInvite*)initWithInviteDefinition:(OFInviteDefinition*)inviteDefinitionIn
{
	self = [super init];
	if(self)
	{
		inviteDefinition = [inviteDefinitionIn retain];
		userMessage = [inviteDefinitionIn.suggestedSenderMessage retain];
	}
	return self;
}

- (OFRequestHandle*)sendInviteToUsers:(NSArray*)users
{
	if(inviteDefinition == nil)
	{
		OFLog(@"You must initialize this invitiation via initWithInviteDefinition to send it");
		return nil;
	}
	
	OFRequestHandle* handle = nil;
	handle = [OFInviteService sendInvite:inviteDefinition
							 withMessage:userMessage
								 toUsers:users
                     onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_sendInviteSuccess)]
                     onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_sendInviteFailure)]];
//							   onSuccess:OFDelegate(self, @selector(_sendInviteSuccess))
//							   onFailure:OFDelegate(self, @selector(_sendInviteFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFInvite class]];
	return handle;
}

- (void)displayAndSendInviteScreen
{
	if(inviteDefinition == nil)
	{
		OFLog(@"You must initialize this invitiation via initWithInviteDefinition to send it");
		return;
	}
	
	[OFInviteService displaySendInviteModal:inviteDefinition.inviteIdentifier];
}

- (OFRequestHandle*)getInviteIcon
{
    OFInvocation* success = nil;
    OFInvocation* failure = nil;
    if(sharedDelegate)
    {
        if([sharedDelegate respondsToSelector:@selector(didGetInviteIcon:OFInvite:)])
        {
            success = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didGetInviteIcon:OFInvite:) userParam:self];
        }
        
        if([sharedDelegate respondsToSelector:@selector(didFailGetInviteIconOFInvite:)])
        {
            failure = [OFInvocation invocationForTarget:sharedDelegate selector:@selector(didFailGetInviteIconOFInvite:) userParam:self];
        }
    }
    OFRequestHandle* handle = [OpenFeint getImageFromUrl:inviteIconURL forModule:[OFInvite class] onSuccess:success onFailure:failure];
	return handle;
}

- (void)_sendInviteSuccess
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didSendInvite:)])
	{
		[sharedDelegate didSendInvite:self];
	}
}

- (void)_sendInviteFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailSendInvite:)])
	{
		[sharedDelegate didFailSendInvite:self];
	}
}


+ (OFService*)getService;
{
	return [OFInviteService sharedInstance];
}

- (void)setSenderUser:(OFUser*)user
{
	OFSafeRelease(senderUser);
	senderUser = [user retain];
}

- (void)setReceiverUser:(OFUser*)user
{
	OFSafeRelease(receiverUser);
	receiverUser = [user retain];
}

setStringFunc(setClientApplicationName, clientApplicationName)
setStringFunc(setClientApplicationID, clientApplicationID)
setStringFunc(setInviteIdentifier, inviteIdentifier)
setStringFunc(setInviteIconURL, inviteIconURL)
setStringFunc(setDeveloperMessage, developerMessage)
setStringFunc(setReceiverNotification, receiverNotification)
setStringFunc(setSenderNotification, senderNotification)
setStringFunc(setUserMessage, userMessage)
setStringFunc(setState, state)



+ (NSString*)getResourceName
{
	return @"invite";
}

- (void) dealloc
{
	OFSafeRelease(senderUser);
	OFSafeRelease(receiverUser);
	OFSafeRelease(clientApplicationName);
	OFSafeRelease(clientApplicationID);
	OFSafeRelease(inviteIdentifier);
	OFSafeRelease(inviteIconURL);
	OFSafeRelease(developerMessage);
	OFSafeRelease(receiverNotification);
	OFSafeRelease(senderNotification);
	OFSafeRelease(userMessage);
	OFSafeRelease(state);
	OFSafeRelease(inviteDefinition);
	[super dealloc];
}


+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        sDataDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setSenderUser:) getter:@selector(senderUser) klass:[OFUser class]], @"sender",
[OFResourceField nestedResourceSetter:@selector(setReceiverUser:) getter:@selector(receiverUser) klass:[OFUser class]], @"receiver",
[OFResourceField fieldSetter:@selector(setClientApplicationName:) getter:@selector(clientApplicationName)], @"client_application_name",
[OFResourceField fieldSetter:@selector(setClientApplicationID:) getter:@selector(clientApplicationID)], @"client_application_id",
[OFResourceField fieldSetter:@selector(setInviteIdentifier:) getter:@selector(inviteIdentifier)], @"invite_identifier",
[OFResourceField fieldSetter:@selector(setInviteIconURL:) getter:@selector(inviteIconURL)], @"invite_icon_url",
[OFResourceField fieldSetter:@selector(setDeveloperMessage:) getter:@selector(developerMessage)], @"developer_message",
[OFResourceField fieldSetter:@selector(setReceiverNotification:) getter:@selector(receiverNotification)], @"receiver_notification",
[OFResourceField fieldSetter:@selector(setSenderNotification:) getter:@selector(senderNotification)], @"sender_notification",
[OFResourceField fieldSetter:@selector(setUserMessage:) getter:@selector(userMessage)], @"user_message",
[OFResourceField fieldSetter:@selector(setState:) getter:@selector(state)], @"state",
        nil] retain];
    }
    return sDataDictionary;
}
@end
