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
#pragma once
#import "OpenFeint/OFCloudStorageService.h"
#import "OFDelegate.h"
@interface OFCloudStorageService (BackwardsCompatibility)
+ (OFRequestHandle*) getIndexOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*)uploadBlob:(NSData*) blob withKey:(NSString*) keyStr onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*)downloadBlobWithKey:(NSString*) keyStr onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

+(OFRequestHandle*)downloadS3Blob:(NSString*)url onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+(OFRequestHandle*)downloadS3Blob:(NSString*)url passThroughUserData:(NSObject*)userData onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+(void)uploadS3Blob:(NSData*)blob withParameters:(OFS3UploadParameters*)parameters passThroughUserData:(NSObject*)userData onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

@end
