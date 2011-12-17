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

#import "OFASIHTTPRequest.h"

//a version of OFASIHTTPRequest that will call the proper OFInvocation without needing any more setup
//you still need to do the startAsynchronous, so you have the chance to add any other headers, etc.


@class OFInvocation;
@interface OFInvocationForwarder : OFASIHTTPRequest
{
    OFInvocation* successInvocation;
    OFInvocation* failureInvocation;
}
+(id) forwarderWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation;

+(id) forwarderWithUrl:(NSURL*) url success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation;
-(id) initWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation;
-(id) initWithUrl:(NSURL*) url success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation;
@end

//does the S3 stuff, handles error codes
@interface OFBlobInvocationForwarder : OFInvocationForwarder
{
    BOOL returnAsS3;
}
+(id) blobForwarderWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation 
                     userData:(NSObject*) userData returnAsS3:(BOOL) returnAsS3;
-(id) initWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation userData:(NSObject*) 
userData returnAsS3:(BOOL) returnAsS3;
@end



