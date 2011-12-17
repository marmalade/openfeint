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

#import "OFRequestHandle.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFASIHTTPRequest.h"
#import "OFDependencies.h"
#import "OpenFeint+Private.h"
#import "OFProvider.h"

@interface OFRequestHandle ()
////////////////////////////////////////////////////////////
/// @internal
/// Designated initializer
/// Initializes the OFRequestHandle with it's wrapped request.
/// @param request The API request that this OFRequestHandle is wrapping
////////////////////////////////////////////////////////////
- (id)initWithRequest:(id)request;

@property (nonatomic, assign, readwrite) id request;
@property (nonatomic, assign, readwrite) Class requestKlass;
@end

@implementation OFRequestHandle

@synthesize request, requestKlass;

+ (OFRequestHandle*)requestHandle:(id)request
{
	return [[[OFRequestHandle alloc] initWithRequest:request] autorelease];
}

- (id)initWithRequest:(id)_request
{
	self = [super init];
	if (self)
	{
		request = _request;
        requestKlass = [request class];
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)cancel
{
	//Because we have different classes that can handle http requests, and its not apperent how to 
	//make them derive from the same class right now, lets just to this until we revamp our http library.
    if ([requestKlass isSubclassOfClass:[MPOAuthAPIRequestLoader class]])
	{
		[[OpenFeint provider] cancelRequest:request];
	}
	else if([requestKlass isSubclassOfClass:[OFASIHTTPRequest class]])
	{
        //the OFProvider system would call completeRequest from inside cancelRequest
        //then exit without calling the delegates.  In order to duplicate this functionality
        //the delegate is being cleared before calling OFASIHTTPRequest's cancel (which does call them)
        [OFRequestHandlesForModule completeRequest:request];
        OFASIHTTPRequest* asiReq = (OFASIHTTPRequest*)request;
        asiReq.delegate = nil;
        asiReq.userInfo = nil;
        [request cancel];
	}
    request = nil;
    requestKlass = nil;
}

@end

NSMutableArray* requests = nil;

@implementation OFRequestHandlesForModule

@synthesize module, handles;

+ (void)addHandle:(OFRequestHandle*)handle forModule:(id)module
{
	if(handle == nil)
	{
		return;
	}
	
	if(requests == nil)
	{
		requests = [[NSMutableArray alloc] initWithCapacity:64];
	}
	
	BOOL bFound = NO;
	for(uint i = 0; i < [requests count]; i++)
	{
		OFRequestHandlesForModule* requestForModule = [requests objectAtIndex:i];
		if(requestForModule.module == module)
		{
			bFound = YES;
			[requestForModule.handles addObject:handle];
			break;
		}
	}
	
	if(!bFound)
	{
		OFRequestHandlesForModule* newRequest = [[[OFRequestHandlesForModule alloc] init] autorelease];
		newRequest.handles = [[[NSMutableArray alloc] initWithCapacity:8] autorelease];
		
		newRequest.module = module;
		[newRequest.handles addObject:handle];
		[requests addObject:newRequest];
	}
}

+ (void)cancelAllRequestsForModule:(id)module
{
	if(requests)
	{
		for(uint i = 0; i < [requests count]; i++)
		{
			OFRequestHandlesForModule* requestForModule = [requests objectAtIndex:i];
			if(requestForModule.module == module)
			{
                // [handle cancel] can mutate the handles array, so copy it to a temp array before
                // fastiterating over it.
                for(OFRequestHandle* handle in [NSArray arrayWithArray:requestForModule.handles])
                {
                    [handle cancel];
                }
				[requests removeObjectAtIndex:i];
                break;
			}
		}
		
		if([requests count] == 0)
		{
			OFSafeRelease(requests);
		}
	}
}

+ (void)completeRequest:(id)completedRequest;
{
	if(requests)
	{
		for(uint i = 0; i < [requests count]; i++)
		{
			OFRequestHandlesForModule* request = [requests objectAtIndex:i];
			for(uint j = 0; j < [request.handles count]; j++)
			{
				OFRequestHandle* handle = [request.handles objectAtIndex:j];
				if(handle.request == completedRequest)
				{
					handle.request = nil;
                    handle.requestKlass = nil;
					[request.handles removeObjectAtIndex:j];
                    break;
				}
			}
		}
	}
}

- (void)dealloc
{
	self.module = nil;
	self.handles = nil;
	[super dealloc];
}

@end
