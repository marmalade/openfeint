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

#import <UIKit/UIKit.h>
#import "OFActionRequestType.h"

@class OFRequestHandle;
@class OFNotificationData;
@class OFInvocation;
@protocol OFProviderProtocol
@required

- (BOOL)isAuthenticated;

- (OFRequestHandle*)performAction:(NSString*)method 
		withParameters:(NSArray*)parameters 
		withHttpMethod:(NSString*)method 
		withSuccessInvocation:(OFInvocation*)success 
		withFailureInvocation:(OFInvocation*)failure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)noticeText;
		
@end
