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

#import "OFTwitterExtendedCredentialController.h"

#import "OFISerializer.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFControllerLoaderObjC.h"
#import "OFActionRequest.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OpenFeint+Private.h"
#import "OFRootController.h"
#import "OFNavigationController.h"
@interface OFTwitterExtendedCredentialController()
@property (nonatomic, retain) OFInvocation* onSuccess;
@property (nonatomic, retain) OFInvocation* onFailure;
@property (nonatomic, retain) OFInvocation* onCancel;
@end

@implementation OFTwitterExtendedCredentialController
@synthesize onSuccess = mOnSuccess;
@synthesize onFailure = mOnFailure;
@synthesize onCancel = mOnCancel;

static NSTimeInterval waitTime = 0.35f;

- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void)getExtendedCredentials:(OFInvocation*)_onSuccess onFailure:(OFInvocation*)_onFailure onCancel:(OFInvocation*)_onCancel;
{
	self.onSuccess = _onSuccess;
	self.onFailure = _onFailure;
	self.onCancel = _onCancel;
	if([OpenFeint getRootController])
	{
		self.title = @"Settings";
		OFNavigationController* navController = [[[OFNavigationController alloc] initWithRootViewController:self] autorelease];
		[[OpenFeint getRootController] presentModalViewController:navController animated:YES];
	}
}

- (void)whenDismissedSuccessfullyAnimate:(BOOL)animated
{
	
}

- (NSString*)getFormSubmissionUrl 
{
	return @"extended_credentials.xml";
}
																													

- (NSString*)singularResourceName
{
	return @"credential";
}

-(void)populateViewDataMap:(NSMutableDictionary*)dataMap
{
    [dataMap setObject:@"password" forKey:[NSNumber numberWithInt:1]];
}

-(void)addHiddenParameters:(NSObject<OFISerializer>*)parameterStream
{
	[super addHiddenParameters:parameterStream];
    [parameterStream ioNSStringToKey:@"credential_type" object:@"twitter"];
}

- (void)dismiss
{
	[[OpenFeint getRootController] dismissModalViewControllerAnimated:YES];
}

- (void)onPresentingErrorDialog
{
    [self.onFailure invoke];
}

-(void)onFormSubmitted:(id)resources
{
	[self dismiss];
    [self.onSuccess invokeWith:NULL afterDelay:waitTime];
}

- (void)cancel
{
	[self dismiss];
    [self.onCancel invokeWith:NULL afterDelay:waitTime];
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
