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

#import "OFUserSettingService.h"

#import "OFService+Private.h"
#import "OFUserSetting.h"
#import "OFUserSettingPushController.h"
#import "OFLeaderboard.h"
#import "OpenFeint+UserOptions.h"
#import "OFNewsletterSubscription.h"
#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFUserSettingService);

@implementation OFUserSettingService

OPENFEINT_DEFINE_SERVICE(OFUserSettingService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFUserSetting class] forKey:[OFUserSetting getResourceName]];
	[namedResourceMap setObject:[OFUserSetting class] forKey:@"setting"]; // @HACK to get getUserSettingWithKey to work.
	[namedResourceMap setObject:[OFUserSettingPushController class] forKey:[OFUserSettingPushController getResourceName]];
	[namedResourceMap setObject:[OFNewsletterSubscription class] forKey:[OFNewsletterSubscription getResourceName]];
}

+ (OFRequestHandle*) getIndexOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"udid" object:[OpenFeint uniqueDeviceId]];

	return [[self sharedInstance]
		getAction:@"users/@me/settings.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:OFActionRequestForeground
		withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Settings")]];
}

+ (void) getUserSettingWithKey:(NSString*)settingKey onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[[self sharedInstance]
	 getAction:[NSString stringWithFormat:@"users/@me/settings/%@.xml", settingKey]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Settings")]];
}

+ (void) setUserSettingWithId:(NSString*)settingId toBoolValue:(BOOL)value onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];

	{
        [params pushScope:@"user_setting" isArray:NO];
		[params ioNSStringToKey:@"id" object:settingId];
		[params ioBoolToKey:@"value" value:value];	
        [params popScope];
	}

	[[self sharedInstance]
		postAction:@"users/@me/settings.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestForeground
		withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Updated Setting")]];
}

+ (void) setUserSettingWithKey:(NSString*)settingKey toBoolValue:(BOOL)value onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	{
        [params pushScope:@"user_setting" isArray:NO];
		[params ioNSStringToKey:@"key" object:settingKey];
		[params ioBoolToKey:@"value" value:value];		
        [params popScope];
	}
	
	[[self sharedInstance]
	 postAction:@"users/@me/settings.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Updated Setting")]];
}

+ (void) setSubscribeToDeveloperNewsLetter:(BOOL)subscribe clientApplicationId:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	clientApplicationId = clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId];
	if (subscribe)
	{
		[[self sharedInstance]
		 postAction:[NSString stringWithFormat:@"client_applications/%@/news_letter_subscription.xml", clientApplicationId]
		 withParameterArray:nil
		 withSuccessInvocation:_onSuccess
		 withFailureInvocation:_onFailure
		 withRequestType:OFActionRequestForeground
		 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Subscribing")]];
	}
	else
	{
		[[self sharedInstance]
		 deleteAction:[NSString stringWithFormat:@"client_applications/%@/news_letter_subscription.xml", clientApplicationId]
		 withParameterArray:nil
		 withSuccessInvocation:_onSuccess
		 withFailureInvocation:_onFailure
		 withRequestType:OFActionRequestForeground
		 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Unsubscribing")]];
	}
}

+ (void) getSubscribingToDeveloperNewsLetter:(NSString*)clientApplicationId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	clientApplicationId = clientApplicationId ? clientApplicationId : [OpenFeint clientApplicationId];
	[[self sharedInstance]
	 getAction:[NSString stringWithFormat:@"client_applications/%@/news_letter_subscription.xml", clientApplicationId]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Retrieving Data")]];
}

@end
