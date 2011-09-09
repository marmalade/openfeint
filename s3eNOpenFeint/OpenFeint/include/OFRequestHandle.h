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

#pragma once

@class MPOAuthAPIRequestLoader;

////////////////////////////////////////////////////////////
/// The OFRequestHandle class wraps an OpenFeint API server request and allows
/// clients to perform actions on that request.
////////////////////////////////////////////////////////////
@interface OFRequestHandle : NSObject
{
@private
	id request;
    Class requestKlass;
}

////////////////////////////////////////////////////////////
/// @internal
/// Creates and returns a new OFRequestHandle.
/// @param handle The API request that this OFRequestHandle is wrapping
////////////////////////////////////////////////////////////
+ (OFRequestHandle*)requestHandle:(id)request;

////////////////////////////////////////////////////////////
/// Cancels the request if it is outstanding.
////////////////////////////////////////////////////////////
- (void)cancel;

@property (nonatomic, readonly) id request;

@end

@interface OFRequestHandlesForModule : NSObject
{
@private
	id module;
	NSMutableArray* handles;
}

+ (void)addHandle:(OFRequestHandle*)handle forModule:(id)module;
+ (void)cancelAllRequestsForModule:(id)module;
+ (void)completeRequest:(id)completedRequest;

@property (nonatomic, retain) NSObject* module;
@property (nonatomic, retain) NSMutableArray* handles;
@end
