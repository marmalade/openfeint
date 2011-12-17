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

#import "OFPushNotificationService.h"

#import "OpenFeint+Private.h"
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFPushNotificationService);

@implementation OFPushNotificationService

OPENFEINT_DEFINE_SERVICE(OFPushNotificationService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
}


+ (void)setDeviceToken:(NSData*)deviceToken onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	if (deviceToken)
	{
		if ([OpenFeint sharedInstance].mUseSandboxPushNotificationServer)
			[params ioNSStringToKey:@"apns_environment" object:@"sandbox"];
		else
			[params ioNSStringToKey:@"apns_environment" object:@"production"];

		[params ioNSStringToKey:@"udid" object:[OpenFeint uniqueDeviceId]];
		
		NSString *tokenString = [NSString stringWithFormat:@"%@", deviceToken];
		tokenString = [tokenString stringByReplacingOccurrencesOfString:@"<" withString:@""];
		tokenString = [tokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
		NSString *tokenEncoded = [tokenString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[params ioNSStringToKey:@"device_token" object:tokenEncoded];
		
		[[self sharedInstance]
		 postAction:@"push_notification_device_tokens.xml"
         withParameterArray:params.getQueryParametersAsMPURLRequestParameters
         withSuccessInvocation:_onSuccess
         withFailureInvocation:_onFailure
		 withRequestType:OFActionRequestSilent
		 withNotice:nil];
	}
	else
	{
		OFLog(@"Nil device token passed to OFPushNotificationService setDeviceToken");
		[_onFailure invoke];
	}
}


@end
