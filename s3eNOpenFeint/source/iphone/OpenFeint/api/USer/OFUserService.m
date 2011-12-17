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

#import "OFUserService.h"
#import "OFUserService+Private.h"
#import "OFService+Private.h"

#import "OFQueryStringWriter.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint.h"
#import "OFUser.h"
#import "OFPaginatedSeries.h"

#import "OFHttpBasicCredential.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFUserService)

@implementation OFUserService

OPENFEINT_DEFINE_SERVICE(OFUserService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];

	[namedResourceMap setObject:[OFHttpBasicCredential class] forKey:[OFHttpBasicCredential getResourceName]];
}

+ (OFRequestHandle*)getUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	// if it's the local user just immediately invoke success with our local user information
	OFUser* localUser = [OpenFeint localUser];
	if ([userId length] == 0 || [userId isEqualToString:localUser.resourceId])
	{
		[_onSuccess invokeWith:[OFPaginatedSeries paginatedSeriesWithObject:localUser]];
		return nil;
	}

	if ([OpenFeint isOnline])
	{
		if (userId == nil)
		{
			userId = @"@me";
		}
		
		return [[self sharedInstance] 
		 getAction:[NSString stringWithFormat:@"users/%@/", userId]
                withParameterArray:nil
                withSuccessInvocation:_onSuccess
                withFailureInvocation:_onFailure
                withRequestType:OFActionRequestSilent
		 withNotice:nil];
	} else {
		[OFUserService 
		 getLocalUser:userId
		 onSuccessInvocation:_onSuccess
		 onFailureInvocation:_onFailure];
		return nil;
	}
}

+ (void)findUsersByName:(NSString*)name pageIndex:(NSInteger)pageIndex onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"name" object:name];
	[params ioIntToKey:@"page" value:pageIndex];
	
	[[self sharedInstance] 
	 getAction:@"users.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void)findUsersForLocalDeviceOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"udid" object:[OpenFeint uniqueDeviceId]];
	
	[[self sharedInstance] 
     _performAction:@"users/for_device.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withHttpMethod:@"GET"
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
     withRequestType:OFActionRequestSilent
     withNotice:nil
     requiringAuthentication:NO];
}

+ (void) getEmailForUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	if (userId == nil)
	{
		userId = @"@me";
	}
	
	[[self sharedInstance] 
	 getAction:[NSString stringWithFormat:@"http_basic_credentials/%@.xml", userId]
     withParameterArray:nil
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

+ (void) setUserLocation:(NSString*)userId location:(CLLocation*)location allowed:(BOOL)allowed onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	if (userId == nil)
	{
		userId = @"@me";
	}
		
	
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	double lat = location.coordinate.latitude;
	double lng = location.coordinate.longitude;
	[params ioDoubleToKey:@"lat" value:lat];
	[params ioDoubleToKey:@"lng" value:lng];

	if (allowed)
	{
		[params ioNSStringToKey:@"allowed" object:@"1"];
	}
	
	[[self sharedInstance] 
	 postAction:[NSString stringWithFormat:@"users/%@/set_location.xml", userId]
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:nil];
}

@end
