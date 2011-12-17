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

#import "OFService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFSocialNotificationService+Private.h"
#import "OFImageUrl.h"
#import "OFResource+ObjC.h"
#import "OFQueryStringWriter.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFSocialNotificationService);

@implementation OFSocialNotificationService

OPENFEINT_DEFINE_SERVICE(OFSocialNotificationService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFImageUrl class] forKey:[OFImageUrl getResourceName]];
}

+ (void)getImageUrlForNotificationImageNamed:(NSString*)imageName onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"image_name" object:imageName];

	[[self sharedInstance] 
		getAction:[NSString stringWithFormat:@"client_applications/%@/notification_images/show.xml", [OpenFeint clientApplicationId]]
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
		withNotice:nil];
}

@end
