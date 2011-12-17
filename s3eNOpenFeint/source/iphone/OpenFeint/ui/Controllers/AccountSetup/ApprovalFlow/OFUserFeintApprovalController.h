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


#import "OFViewController.h"

@class OFInvocation;

@interface OFUserFeintApprovalController : OFViewController
{
@protected
    UILabel *appNameLabel;
    OFInvocation* mApprovedInvocation;
    OFInvocation* mDeniedInvocation;
}

@property (nonatomic, retain) IBOutlet UILabel *appNameLabel;
@property (nonatomic, retain) OFInvocation* approvedInvocation;
@property (nonatomic, retain) OFInvocation* deniedInvocation;


- (IBAction)clickedUseFeint;
- (IBAction)clickedDontUseFeint;
- (IBAction)onTerms;

@end
