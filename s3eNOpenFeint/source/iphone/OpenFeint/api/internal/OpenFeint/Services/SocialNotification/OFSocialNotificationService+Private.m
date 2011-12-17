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

#import "OFSocialNotificationService.h"
#import "OFSocialNotificationService+Private.h"

#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OFUsersCredentialService.h"
#import "OFUsersCredential.h"
#import "OFPaginatedSeries.h"
#import "OFTableSectionDescription.h"
#import "OFUnlockedAchievement.h"
#import "OFAchievement.h"
#import "OFSocialNotificationApi.h"
#import "OFSendSocialNotificationController.h"

@implementation OFSocialNotificationService (Private)

+ (void)sendSocialNotification:(OFSocialNotification*)socialNotification 
                onSuccess:(OFInvocation*)onSuccess onFailure:(OFInvocation*)onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"msg" object:socialNotification.text];
	[params ioNSStringToKey:@"image_type" object:socialNotification.imageType];
	
	for(uint i = 0; i < [socialNotification.sendToNetworks count]; i++)
	{
		NSNumber* typeNumber = [socialNotification.sendToNetworks objectAtIndex:i];
		switch([typeNumber intValue])
		{
			case ESocialNetworkCellType_FACEBOOK:
			{
				[params ioNSStringToKey:@"networks[]" object:@"Fbconnect"];			
			}
			break;
				
			case ESocialNetworkCellType_TWITTER:
			{
				[params ioNSStringToKey:@"networks[]" object:@"Twitter"];
			}
			break;
		};
	}
	
	if([socialNotification.imageType isEqualToString:@"notification_images"])
	{
		[params ioNSStringToKey:@"image_name" object:socialNotification.imageIdentifier];
	}
	else
	{
		[params ioNSStringToKey:@"image_id" object:socialNotification.imageIdentifier];
	}
	[params ioNSStringToKey:@"url" object:socialNotification.url];
	
	OFNotificationData* noticeData = [OFNotificationData 
		dataWithText:[NSString stringWithFormat:@"Published Game Event: %@", socialNotification.text] 
		andCategory:kNotificationCategorySocialNotification
		andType:kNotificationTypeSubmitting];
	noticeData.notificationUserData = socialNotification;
	
//	OFDelegate success = OFDelegate(self, @selector(_notificationSent));	
//	OFDelegate failure = OFDelegate(self, @selector(_notificationFailed));

	[[self sharedInstance]
	 postAction:@"notifications.xml"
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:onSuccess
	 withFailureInvocation:onFailure
	 withRequestType:OFActionRequestBackground
	 withNotice:noticeData];
}

@end
