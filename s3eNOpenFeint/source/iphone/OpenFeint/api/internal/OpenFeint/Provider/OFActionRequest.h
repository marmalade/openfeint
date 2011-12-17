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

#import <UIKit/UIKit.h>
#import "OFActionRequestType.h"

@class OFNotificationData;
@class MPOAuthAPIRequestLoader;

// If this changes, the server configrations must be updated. 
typedef enum {
    OpenFeintHttpStatusCodeSeriousError = 400,
    OpenFeintHttpStatusCodeNotAcceptable = 406,
    OpenFeintHttpStatusCodeForServerMaintanence = 450,
    OpenFeintHttpStatusCodeNotAuthorized = 401,
    OpenFeintHttpStatusCodeUpdateRequired = 426,
    OpenFeintHttpStatusCodePermissionsRequired = 430,
    OpenFeintHttpStatusCodeNotFound = 404,
    OpenFeintHttpStatusCodeForbidden = 403,
    OpenFeintHttpStatusCodeOK = 200
} OFHttpStatusCodes;

@interface OFActionRequest : NSObject
{
	MPOAuthAPIRequestLoader* mLoader;
	OFActionRequestType mRequestType;
	OFNotificationData* mNoticeData;
	int mPreviousHttpStatusCode;
	BOOL mRequiresAuthentication;
}

@property (nonatomic, readonly) OFNotificationData* notice;
@property (nonatomic, readonly) BOOL failedNotAuthorized;
@property (nonatomic, readonly) BOOL requiresAuthentication;
@property (nonatomic, readonly) MPOAuthAPIRequestLoader* loader;

+ (id)actionRequestWithLoader:(MPOAuthAPIRequestLoader*)loader withRequestType:(OFActionRequestType)requestType withNotice:(OFNotificationData*)noticeData requiringAuthentication:(BOOL)requiringAuthentication;

- (id)initWithLoader:(MPOAuthAPIRequestLoader*)loader withRequestType:(OFActionRequestType)requestType withNotice:(OFNotificationData*)noticeData requiringAuthentication:(BOOL)requiringAuthentication;
- (void)dispatch;

- (void)abandonInLightOfASeriousError;

@end

