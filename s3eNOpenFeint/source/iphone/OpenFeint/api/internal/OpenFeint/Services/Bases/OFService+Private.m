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

#import "OFService+Private.h"
#import "OFService+Overridables.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthURLResponse.h"
#import "OFResource.h"
#import "OFPaginatedSeries.h"
#import "OFNotification.h"
#import "OFInvocation.h"
#import "OFResource+ObjC.h"
#import "OFXmlElement.h"


#define OF_SERVICE_DEBUG_REQUESTS 0

@implementation OFService ( Private )

- (void)_onActionFailed:(MPOAuthAPIRequestLoader*)request nextInvocation:(OFInvocation*)next
{
	[next invokeWith:request];
}

- (void)_onActionSucceeded:(MPOAuthAPIRequestLoader*)request nextInvocation:(OFInvocation*)next
{
    
#if OF_SERVICE_DEBUG_REQUESTS
    OFLog(@"Got response:\n%@", [request responseString]);
#endif
    
    OFXmlElement* doc = [OFXmlElement elementWithData:request.data];
    OFPaginatedSeries* paginatedSeries = [OFResource resourcesFromXml:doc withMap:self.knownResources];
    
	if ([request.oauthResponse.urlResponse isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)request.oauthResponse.urlResponse;
		paginatedSeries.httpResponseStatusCode = [httpResponse statusCode];
	}
	
	//If there is a default notice to show, then show it here.
	[[OFNotification sharedInstance] showDefaultNotice];
	
	[next invokeWith:paginatedSeries];
}

- (OFRequestHandle*)getAction:(NSString*)action
            withParameterArray:(NSArray*) paramArray
         withSuccessInvocation:(OFInvocation*)onSuccess 
         withFailureInvocation:(OFInvocation*)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	return [self 
		_performAction:action
            withParameterArray:paramArray
		withHttpMethod:@"GET"
            withSuccessInvocation:onSuccess
            withFailureInvocation:onFailure
		withRequestType:requestType
		withNotice:notice
            requiringAuthentication:YES];
}

- (OFRequestHandle*)postAction:(NSString*)action
            withParameterArray:(NSArray*) paramArray
         withSuccessInvocation:(OFInvocation*)onSuccess 
         withFailureInvocation:(OFInvocation*)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	return [self 
		_performAction:action
            withParameterArray:paramArray
		withHttpMethod:@"POST"
            withSuccessInvocation:onSuccess
            withFailureInvocation:onFailure
		withRequestType:requestType
            withNotice:notice
            requiringAuthentication:YES];
}

- (OFRequestHandle*)putAction:(NSString*)action
            withParameterArray:(NSArray*) paramArray
         withSuccessInvocation:(OFInvocation*)onSuccess 
         withFailureInvocation:(OFInvocation*)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	return [self 
		_performAction:action
            withParameterArray:paramArray
		withHttpMethod:@"PUT"
            withSuccessInvocation:onSuccess
            withFailureInvocation:onFailure
		withRequestType:requestType
            withNotice:notice
            requiringAuthentication:YES];
}

- (OFRequestHandle*)deleteAction:(NSString*)action
            withParameterArray:(NSArray*) paramArray
         withSuccessInvocation:(OFInvocation*)onSuccess 
         withFailureInvocation:(OFInvocation*)onFailure
	 withRequestType:(OFActionRequestType)requestType
		  withNotice:(OFNotificationData*)notice
{
	return [self 
		 _performAction:action
            withParameterArray:paramArray
		 withHttpMethod:@"DELETE"
            withSuccessInvocation:onSuccess
            withFailureInvocation:onFailure
		 withRequestType:requestType
            withNotice:notice
            requiringAuthentication:YES];
}            


- (OFRequestHandle*)_performAction:(NSString*)action
                withParameterArray:(NSArray*)paramArray
                    withHttpMethod:(NSString*)httpMethod
             withSuccessInvocation:(OFInvocation*)onSuccess 
             withFailureInvocation:(OFInvocation*)onFailure
                   withRequestType:(OFActionRequestType)requestType
                        withNotice:(OFNotificationData*)notice
           requiringAuthentication:(BOOL)requiringAuthentication 
{	
    return [[OpenFeint provider] 
            performAction:action
            withParameters:paramArray
            withHttpMethod:httpMethod
            withSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onActionSucceeded:nextInvocation:) chained:onSuccess thread:[[OpenFeint provider] requestThread]]
            withFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onActionFailed:nextInvocation:) chained:onFailure thread:[[OpenFeint provider] requestThread]]
            withRequestType:requestType
            withNotice:notice
            requiringAuthentication:requiringAuthentication];
    
}

@end
