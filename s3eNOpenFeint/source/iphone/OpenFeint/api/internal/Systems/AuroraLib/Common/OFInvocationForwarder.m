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

#import "OFInvocationForwarder.h"
#import "OFInvocation.h"
#import "OFSettings.h"
#import "OFS3Response.h"
#import "OFCompressableData.h"
#import "NSURL+OpenFeint.h"
#import "OFDependencies.h"

@interface OFInvocationForwarder ()
@property (nonatomic, retain) OFInvocation* successInvocation;
@property (nonatomic, retain) OFInvocation* failureInvocation;
@end



@implementation OFInvocationForwarder
@synthesize successInvocation;
@synthesize failureInvocation;

+(id) forwarderWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation
{
    return [[[OFInvocationForwarder alloc] initWithString:urlString success:successInvocation failure:failureInvocation] autorelease];
}


+(id) forwarderWithUrl:(NSURL*) url success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation
{
    return [[[OFInvocationForwarder alloc] initWithUrl:url success:successInvocation failure:failureInvocation] autorelease];
}

-(id) initWithString:(NSString*) _urlString success:(OFInvocation*) _successInvocation failure:(OFInvocation*) _failureInvocation
{
    NSURL*pathUrl = [NSURL OFURLWithString:_urlString];
    return [self initWithUrl:pathUrl success:_successInvocation failure:_failureInvocation];
}


-(id) initWithUrl:(NSURL*) _url success:(OFInvocation*) _successInvocation failure:(OFInvocation*) _failureInvocation
{
    if((self = [super initWithURL:_url]))
    {
        self.successInvocation = _successInvocation;
        self.failureInvocation = _failureInvocation;
        [self setDelegate:self];  //there's something you don't see everyday...        
    }
    return self;
}

-(void)dealloc
{
    self.successInvocation = nil;
    self.failureInvocation = nil;
    [super dealloc];
}

- (void)requestFinished:(OFASIHTTPRequest *)_request {
    OFInvocationForwarder* forwarder = (OFInvocationForwarder*) _request;
    [forwarder.successInvocation invokeWith:_request.responseData];
}
- (void)requestFailed:(OFASIHTTPRequest *)_request {
    OFInvocationForwarder* forwarder = (OFInvocationForwarder*)_request;
    [forwarder.failureInvocation invoke];
}

@end

@implementation OFBlobInvocationForwarder
+(id) blobForwarderWithString:(NSString*) urlString success:(OFInvocation*) successInvocation failure:(OFInvocation*) failureInvocation 
                     userData:(NSObject*) userData returnAsS3:(BOOL) returnAsS3
{
    return [[[OFBlobInvocationForwarder alloc] initWithString:urlString success:successInvocation failure:failureInvocation 
                                                     userData:userData returnAsS3:returnAsS3] autorelease];
}

-(id) initWithString:(NSString*) _urlString success:(OFInvocation*) _successInvocation failure:(OFInvocation*) _failureInvocation 
            userData:(NSObject*) userData returnAsS3:(BOOL) _returnAsS3
{
    if((self = [super initWithString:_urlString success:_successInvocation failure:_failureInvocation]))
    {
        returnAsS3 = _returnAsS3;
        if(userData)
            self.userInfo = [NSDictionary dictionaryWithObject:userData forKey:@"blobUserData"];
    }
    return self;
}

- (void)requestFinished:(OFASIHTTPRequest *)_request {
    int statusCode = _request.responseStatusCode;
    if(statusCode >=200 && statusCode <=299)
    {
        NSData* data = _request.responseData;
        if(returnAsS3)
        {
            //TODO: userParam?  this must be an NSDictionary for OFASIHTTPRequests
            OFS3Response* response = [[[OFS3Response alloc] initWithData:data andUserParam:[_request.userInfo objectForKey:@"blobUserData"] andStatusCode:statusCode] autorelease];
            [self.successInvocation invokeWith:response];
        }
        else             
        {    
            [self.successInvocation invokeWith:[OFCompressableData uncompressedDataFromSerializedData:data]];
        }
    }
    else 
    {        
        OFLog(@"Request failed with status code: %d", statusCode);
        [self requestFailed:_request];
    }

}

- (void)requestFailed:(OFASIHTTPRequest *)_request {
    if(returnAsS3)
    {
        //TODO: userParam?  this must be an NSDictionary for OFASIHTTPRequests
        OFS3Response* response = [[[OFS3Response alloc] initWithData:nil andUserParam:[_request.userInfo objectForKey:@"blobUserData"] andStatusCode:_request.responseStatusCode] autorelease];
        [self.failureInvocation invokeWith:response];
    }
    else 
    {
        [self.failureInvocation invoke];
    }
}

@end


