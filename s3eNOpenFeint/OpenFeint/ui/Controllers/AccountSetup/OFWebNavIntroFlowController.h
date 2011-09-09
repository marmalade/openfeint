////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>

#import "OFWebNavController.h"

@interface OFWebNavIntroFlowController : OFWebNavController {
    OFDelegate approvedDelegate;
    OFDelegate deniedDelegate;
    
    BOOL createdNewAccount;
}

+ (id)controller;

- (void)setApprovedDelegate:(const OFDelegate&)approvedDelegate andDeniedDelegate:(const OFDelegate&)deniedDelegate;
- (void)setNavbarVisibility;
- (void)showOfflinePage:(NSString*)pageName;

- (void)bootstrapSuccess;
- (void)bootstrapFailed;

- (void)actionApprove:(NSDictionary*)options;
- (void)actionNavigateToURLWithUDID:(NSDictionary*)options;
- (void)actionBootstrap:(NSDictionary*)options;

@end
