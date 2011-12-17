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

#import "OFTimeStampService.h"
#import "OFActionRequestType.h"
#import "OFService+Private.h"
#import "OFPaginatedSeries.h"
#import "OFTimeStamp.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFTimeStampService);

@implementation OFTimeStampService

OPENFEINT_DEFINE_SERVICE(OFTimeStampService);

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFTimeStamp class] forKey:[OFTimeStamp getResourceName]];
}

+ (OFRequestHandle*) getServerTimeOnSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	return [[self sharedInstance] getAction:@"server_timestamp"
                         withParameterArray:nil
                      withSuccessInvocation:_onSuccess
                      withFailureInvocation:_onFailure
							withRequestType:OFActionRequestSilent
								 withNotice:nil];
}

@end

