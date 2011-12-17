//  Copyright 2011 Aurora Feint, Inc.
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
#import "OFCloudStorageService+BackwardsCompatibility.h"
@implementation OFCloudStorageService (BackwardsCompatibility)
+ (OFRequestHandle*) getIndexOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getIndexOnSuccessInvocation:onSuccess.getInvocation() 
                         onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*)uploadBlob:(NSData*) blob withKey:(NSString*) keyStr onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self uploadBlob:blob withKey:keyStr 
        onSuccessInvocation:onSuccess.getInvocation() 
        onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*)downloadBlobWithKey:(NSString*) keyStr onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self downloadBlobWithKey:keyStr 
                 onSuccessInvocation:onSuccess.getInvocation() 
                 onFailureInvocation:onFailure.getInvocation()];
}

+(OFRequestHandle*)downloadS3Blob:(NSString*)url onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	return [OFCloudStorageService downloadS3Blob:url passThroughUserData:nil onSuccess:onSuccess onFailure:onFailure];
}

+(OFRequestHandle*)downloadS3Blob:(NSString*)url passThroughUserData:(NSObject*)userData onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self downloadS3Blob:url passThroughUserData:userData onSuccessInvocation:onSuccess.getInvocation() onFailureInvocation:onFailure.getInvocation()];
}

+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self uploadS3Blob:blob withParameters:parameters 
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters passThroughUserData:(NSObject*)userData onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self uploadS3Blob:blob withParameters:parameters 
   passThroughUserData:userData
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}

@end
