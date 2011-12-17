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

#include "OFDoBootstrapController.h"

#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFReachability.h"
#import "OFControllerLoaderObjC.h"
#import "OFUserService.h"
#import "OFUser.h"
#import "OFPaginatedSeries.h"
#import "OFPatternedGradientView.h"
#import "OFContentFrameView.h"

#import "OFNewAccountController.h"
#import "OFExistingAccountController.h"
#import "OFIntroNavigationController.h"
#import "OFDependencies.h"

@interface OFDoBootstrapController ()
- (void)dismiss;
- (void)_findUsersSucceeded:(OFPaginatedSeries*)resources;
- (void)_findUsersFailed;
- (void)_bootstrapSucceded;
- (void)_bootstrapFailed;
- (void)_showMessageAndHideLoading:(NSString*)message;
@end

@implementation OFDoBootstrapController

@synthesize titleLabel, messageLabel, activityIndicator;
@synthesize onCompletionInvocation;

- (void)_showMessageAndHideLoading:(NSString*)message
{
	activityIndicator.hidden = YES;    
    titleLabel.text = OFLOCALSTRING(@"Error");
    messageLabel.hidden = NO;
	[messageLabel setText:message];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //if ([OpenFeint isLargeScreen]) self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
	[OpenFeint allowErrorScreens:NO];

	self.navigationItem.hidesBackButton = YES;

	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[[self navigationController] setNavigationBarHidden:YES animated:YES];

	if (!OFReachability.isConnectedToInternet)
	{
		[self _showMessageAndHideLoading:OFLOCALSTRING(@"You're offline! OpenFeint needs to connect to the internet one time to look up or create your account. Please connect to the internet and restart this application to enable OpenFeint.")];
	}
	else
	{
		[OFUserService findUsersForLocalDeviceOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_findUsersSucceeded:)] 
                                              onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_findUsersFailed)]];
	}
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOff" object:nil];
}

- (void)dealloc
{
	self.messageLabel = nil;
	self.activityIndicator = nil;
	self.onCompletionInvocation = nil;
	[super dealloc];
}

- (void)dismiss
{
	[OpenFeint allowErrorScreens:YES];
	[OpenFeint dismissRootControllerOrItsModal];
}

- (void)_findUsersSucceeded:(OFPaginatedSeries*)resources
{
	int numUsers = [resources count];
	
	if (numUsers == 0)
	{
		[OpenFeint doBootstrapAsNewUserOnSuccess:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapSucceded)] 
                                       onFailure:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapFailed)]];
	}
	else if (numUsers == 1)
	{
		[OpenFeint doBootstrapAsUserId:[(OFUser*)[resources objectAtIndex:0] resourceId] 
                             onSuccess:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapSucceded)] 
                             onFailure:[OFInvocation invocationForTarget:self selector:@selector(_bootstrapFailed)]];
	}
	else
	{
		OFExistingAccountController* accountController = (OFExistingAccountController*)[[OFControllerLoaderObjC loader] load:@"ExistingAccountMultiple"];// load(@"ExistingAccountMultiple");
		[[accountController selectUserWidget] setHideHeader:YES];
		[[accountController selectUserWidget] setUserResources:resources];
        accountController.onCompletionInvocation = self.onCompletionInvocation;
//		[accountController setCompleteDelegate:mCompleteDelegate];
		UINavigationController* navController = [self navigationController];
		[navController pushViewController:accountController animated:YES];
	}
}

- (void)_findUsersFailed
{
	[self _bootstrapFailed];
}

- (void)_bootstrapSucceded
{
	BOOL newAccount = [OpenFeint loggedInUserIsNewUser];
	if (newAccount)
	{
		OFNewAccountController* accountController = (OFNewAccountController*)[[OFControllerLoaderObjC loader] load:@"NewAccount"];// load(@"NewAccount");
		accountController.hideNavigationBar = YES;
		accountController.closeDashboardOnCompletion = YES;
        accountController.onCompletionInvocation = self.onCompletionInvocation;
//		[accountController setCompleteDelegate:mCompleteDelegate];
        if([OpenFeint isLargeScreen])
        {
            [accountController hideContentFrame];
        }
		[[self navigationController] pushViewController:accountController animated:NO];
	}
	else
	{
		OFExistingAccountController* accountController = (OFExistingAccountController*)[[OFControllerLoaderObjC loader] load:@"ExistingAccount"];// load(@"ExistingAccount");
        accountController.onCompletionInvocation = self.onCompletionInvocation;
//		[accountController setCompleteDelegate:mCompleteDelegate];
		UINavigationController* navController = [self navigationController];
		[navController pushViewController:accountController animated:NO];
	}
}

- (void)_bootstrapFailed
{
	[self _showMessageAndHideLoading:OFLOCALSTRING(@"OpenFeint failed to initialize. Restarting this application while connected to the internet, or reinstalling it, may fix this error. E-mail help@openfeint.com if you're having trouble.")];
}

- (IBAction)_skip
{
	[self dismiss];
    [self.onCompletionInvocation invoke];
//	mCompleteDelegate.invoke();
}

//- (void)setCompleteDelegate:(OFDelegate&)completeDelegate
//{
//	mCompleteDelegate = completeDelegate;
//}

@end
