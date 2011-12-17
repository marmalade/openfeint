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

#import "OFFacebookExtendedCredentialController.h"
#import "OFFBConnect.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFNavigationController.h"
#import "OFFacebookAccountController.h"
#import "OFControllerLoaderObjC.h"
#import "OFActionRequest.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"
#import "OFRootController.h"
#import "OFSendSocialNotificationController.h"
#import "OFDependencies.h"

@interface OFFacebookExtendedCredentialController()
@property (nonatomic, retain) OFInvocation* onSuccess;
@property (nonatomic, retain) OFInvocation* onFailure;
@property (nonatomic, retain) OFInvocation* onCancel;
@end




@implementation OFFacebookExtendedCredentialController
@synthesize onSuccess = mOnSuccess;
@synthesize onFailure = mOnFailure;
@synthesize onCancel = mOnCancel;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}



- (void)dialogDidCancel:(OFTFBDialog*)dialog
{
	[super closeLoginDialog];	
    [self.onCancel invoke];

}

- (void)onFormSubmitted:(id)resources
{
    [self.onSuccess invoke];
}


- (void)displayError:(NSString*)errorString
{
	[[[[UIAlertView alloc] 
	   initWithTitle:OFLOCALSTRING(@"Facebook Connect Error")
	   message:errorString
	   delegate:nil
	   cancelButtonTitle:OFLOCALSTRING(@"Ok")
	   otherButtonTitles:nil] autorelease] show];

    [self.onFailure invoke];

}

- (NSString*)singularResourceName
{
	return @"credential";
}

-(void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
}

- (void)getExtendedCredentials:(OFInvocation*)_onSuccess onFailure:(OFInvocation*)_onFailure onCancel:(OFInvocation*)_onCancel;
{
	self.onSuccess = _onSuccess;
	self.onFailure = _onFailure;
	self.onCancel = _onCancel;
	skipLoginOnAppear = YES;
	self.getPostingPermission = YES;
	[super promptToLogin];
}

- (void)registerActionsNow
{
}

- (void)dealloc 
{
    self.onSuccess = nil;
    self.onCancel = nil;
    self.onFailure = nil;
	[super dealloc];
}

@end
