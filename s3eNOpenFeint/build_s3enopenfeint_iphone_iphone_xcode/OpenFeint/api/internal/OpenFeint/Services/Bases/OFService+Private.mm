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

#import "OFDependencies.h"
#import "OFService+Private.h"
#import "OFService+Overridables.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "OFDelegateChained.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPOAuthURLResponse.h"
#import "OFResource.h"
#import "OFXmlDocument.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFDelegate.h"
#import "OFPaginatedSeries.h"
#import "OFNotification.h"

#define OF_SERVICE_DEBUG_REQUESTS 0

@implementation OFService ( Private )

- (void)_onActionFailed:(MPOAuthAPIRequestLoader*)request nextCall:(OFDelegateChained*)next
{
	[next invokeWith:request];
}

- (void)_onActionSucceeded:(MPOAuthAPIRequestLoader*)request nextCall:(OFDelegateChained*)next
{
    
#if OF_SERVICE_DEBUG_REQUESTS
    OFLog(@"Got response:\n%@", [request responseString]);
#endif
    
	OFXmlDocument* doc = [OFXmlDocument xmlDocumentWithData:request.data];
	OFPaginatedSeries* paginatedSeries = [OFResource resourcesFromXml:doc withMap:[self getKnownResources]];
	if ([request.oauthResponse.urlResponse isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)request.oauthResponse.urlResponse;
		paginatedSeries.httpResponseStatusCode = [httpResponse statusCode];
	}
	
	//If there is a default notice to show, then show it here.
	[[OFNotification sharedInstance] showDefaultNotice];
	
	[next invokeWith:paginatedSeries];
}

- (OFRequestHandle*)_performAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withHttpMethod:(NSString*)httpMethod
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{    
	return [self _performAction:action
		withParameters:params
		withHttpMethod:httpMethod
		withSuccess:onSuccess
		withFailure:onFailure
		withRequestType:requestType
		withNotice:notice
		requiringAuthentication:true];
}

- (OFRequestHandle*)_performAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withHttpMethod:(NSString*)httpMethod
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
		requiringAuthentication:(bool)requiringAuthentication
{
#if OF_SERVICE_DEBUG_REQUESTS
    OFLog(@"Sent request: %@ %@", httpMethod, action);
#endif

	return [[OpenFeint provider] 
		performAction:action
		withParameters:(params ? params->getQueryParametersAsMPURLRequestParameters() : nil)
		withHttpMethod:httpMethod
		withSuccess:OFDelegate(self, @selector(_onActionSucceeded:nextCall:), onSuccess, [[OpenFeint provider] requestThread])
		withFailure:OFDelegate(self, @selector(_onActionFailed:nextCall:), onFailure, [[OpenFeint provider] requestThread])
		withRequestType:requestType
		withNotice:notice
		requiringAuthentication:requiringAuthentication];
}


- (OFRequestHandle*)getAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	return [self 
		getAction:action
		withParameters:params
		withSuccess:onSuccess
		withFailure:onFailure
		withRequestType:requestType
		withNotice:notice
		requiringAuthentication:true];
}

- (OFRequestHandle*)getAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
		requiringAuthentication:(bool)requiringAuthentication
{
	return [self 
		_performAction:action
		withParameters:params
		withHttpMethod:@"GET"
		withSuccess:onSuccess
		withFailure:onFailure
		withRequestType:requestType
		withNotice:notice
		requiringAuthentication:requiringAuthentication];
}

- (OFRequestHandle*)postAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	return [self 
		_performAction:action
		withParameters:params
		withHttpMethod:@"POST"
		withSuccess:onSuccess
		withFailure:onFailure
		withRequestType:requestType
		withNotice:notice];
}

- (OFRequestHandle*)putAction:(NSString*)action
		withParameters:(OFHttpNestedQueryStringWriter*)params
		withSuccess:(const OFDelegate&)onSuccess 
		withFailure:(const OFDelegate&)onFailure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)notice
{
	OFPointer<OFHttpNestedQueryStringWriter> newParams;
	if (params == nil)
	{
		newParams = new OFHttpNestedQueryStringWriter;
		params = newParams.get();
	}
	
	return [self 
		_performAction:action
		withParameters:params
		withHttpMethod:@"PUT"
		withSuccess:onSuccess
		withFailure:onFailure
		withRequestType:requestType
		withNotice:notice];
}

- (OFRequestHandle*)deleteAction:(NSString*)action
	  withParameters:(OFHttpNestedQueryStringWriter*)params
		 withSuccess:(const OFDelegate&)onSuccess 
		 withFailure:(const OFDelegate&)onFailure
	 withRequestType:(OFActionRequestType)requestType
		  withNotice:(OFNotificationData*)notice
{
	OFPointer<OFHttpNestedQueryStringWriter> newParams;
	if (params == nil)
	{
		newParams = new OFHttpNestedQueryStringWriter;
		params = newParams.get();
	}
	
	return [self 
		 _performAction:action
		 withParameters:params
		 withHttpMethod:@"DELETE"
		 withSuccess:onSuccess
		 withFailure:onFailure
		 withRequestType:requestType
		 withNotice:notice];
}

@end
