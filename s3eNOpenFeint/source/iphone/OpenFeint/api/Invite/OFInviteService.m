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

#import "OFInviteService.h"
#import "OFService+Private.h"

#import "OFInvite.h"
#import "OFInviteDefinition.h"
#import "OFPaginatedSeries.h"
#import "OpenFeint+UserOptions.h"
#import "OFSelectInviteTypeController.h"
#import "OFUser.h"
#import "OpenFeint+Private.h"
#import "OFInviteNotificationController.h"
#import "OFFramedNavigationController.h"
#import "OFControllerLoaderObjC.h"
#import "OFDeviceContact.h"
#import "UIButton+OpenFeint.h"
#import "NSInvocation+OpenFeint.h"
#import "OFInviteNotificationController.h"
#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFInviteService)

@implementation OFInviteService

OPENFEINT_DEFINE_SERVICE(OFInviteService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
	[namedResourceMap setObject:[OFInvite class] forKey:[OFInvite getResourceName]];
	[namedResourceMap setObject:[OFInviteDefinition class] forKey:[OFInviteDefinition getResourceName]];
}

+ (OFRequestHandle*)getDefaultInviteDefinitionForApplicationInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{

	return [[self sharedInstance] 
	 getAction:@"invite_definitions/primary"
            withParameterArray:nil
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (OFRequestHandle*)getInviteDefinition:(NSString*)inviteIdentifier onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
  OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	return [[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"invite_definitions/%@.xml", inviteIdentifier]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (OFRequestHandle*)sendInvite:(OFInviteDefinition*)inviteDefinition withMessage:(NSString*)userMessage toUsers:(NSArray*)users onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"key" object:( inviteDefinition.resourceId)]; 
	[params ioNSStringToKey:@"invite[sender_message]" object:userMessage];
	
	for(OFResource* resource in users) 
	{
		if([resource isKindOfClass:[OFUser class]])
		{
			[params ioNSStringToKey:@"invite[receivers][]" object:( resource.resourceId)]; 
		}
		else if([resource isKindOfClass:[OFDeviceContact class]])
		{
			OFDeviceContact* contact = (OFDeviceContact*)resource;
			if(contact.number && ![contact.number isEqualToString:@""])
			{
				[params ioNSStringToKey:@"invite[sms_receivers][]" object:( contact.number)];
			}
			else if(contact.email && ![contact.email isEqualToString:@""])
			{
				[params ioNSStringToKey:@"invite[email_receivers][]" object:( contact.email)];
			}
			
		}
	}
	
	return [[self sharedInstance] 
	 postAction:@"invites.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)getInvitesForUser:(OFUser*)user pageIndex:(unsigned int)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer]; 
	[params ioIntToKey:@"page" value:pageIndex]; 
	NSString* markViewed = @"true";
	[params ioNSStringToKey:@"mark_viewed" object:markViewed];

	[[self sharedInstance] 
	 getAction:@"invites.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)ignoreInvite:(NSString*)inviteResourceId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[[self sharedInstance] 
	 putAction:[NSString stringWithFormat:@"invites/%@/ignore", inviteResourceId]
	 withParameterArray:nil
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];	
}


+ (void)displaySendInviteModal:(NSString*)inviteIdentifier
{
	OFSelectInviteTypeController* controller = [OFSelectInviteTypeController inviteTypeControllerWithInviteIdentifier:inviteIdentifier];
	[controller openAsModal];
}

@end
