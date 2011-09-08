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

#include "OFExistingAccountController.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OFControllerLoader.h"
#import "OFOpenFeintAccountLoginController.h"
#import "OFDeadEndErrorController.h"
#import "OFLinkSocialNetworksController.h"
#import "OFUser.h"
#import "OFViewHelper.h"

@interface OFExistingAccountController ()
- (void)popBackToMe;
- (void)dismiss;
- (void)onBootstrapFailure;
- (void)continueFlow;
@end

@implementation OFExistingAccountController

@synthesize appNameLabel,
            usernameLabel,
			scoreLabel,
            profileImageView,
			selectUserWidget,
			editButton;
			// closeDashboardOnCompletion; // DIAG_GetTheMost

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([OpenFeint isLargeScreen]) self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationItem.hidesBackButton = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOff" object:nil];
    
    UIButton *button = (UIButton*)OFViewHelper::findViewByTag(self.view, 1);
    UIImage *buttonBg = [[button backgroundImageForState:UIControlStateNormal] stretchableImageWithLeftCapWidth:7 topCapHeight:7];
    [button setBackgroundImage:buttonBg forState:UIControlStateNormal];
    
    appNameLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"Now Playing %@"), [OpenFeint applicationDisplayName]];
    
	if (self.selectUserWidget == nil)
	{
		usernameLabel.text = [OpenFeint lastLoggedInUserName];
		scoreLabel.text = [NSString stringWithFormat:@"%d", [OpenFeint localUser].gamerScore];
        [profileImageView useLocalPlayerProfilePictureDefault];
        profileImageView.imageUrl = [OpenFeint lastLoggedInUserProfilePictureUrl];
	}

	[super viewWillAppear:animated];
}

+ (void)customAnimateNavigationController:(UINavigationController*)navController animateIn:(BOOL)animatingIn
{
	if (animatingIn)
	{
		[navController setNavigationBarHidden:NO animated:NO];
	}
	else
	{
		[navController setNavigationBarHidden:YES animated:NO];
	}
	
	CGRect navBarFrame = navController.navigationBar.frame;
	
	//When modifying the frames y, we have to take into the frame - which is approx 4.
	const float FRAME_SIZE = 4.f;
	
	navBarFrame.origin.y = animatingIn ? -navBarFrame.size.height + FRAME_SIZE : FRAME_SIZE;
	navController.navigationBar.frame = navBarFrame;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5f];
	navBarFrame.origin.y = animatingIn ? FRAME_SIZE : -navBarFrame.size.height + FRAME_SIZE;
	navController.navigationBar.frame = navBarFrame;
	[UIView commitAnimations];
}

- (void)viewDidAppear:(BOOL)animated
{
	[OFExistingAccountController customAnimateNavigationController:[self navigationController] animateIn:NO];
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[OFExistingAccountController customAnimateNavigationController:[self navigationController] animateIn:YES];
	//[OpenFeint startLocationManagerIfAllowed];
	[super viewDidDisappear:animated];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (void)dealloc
{
    self.appNameLabel = nil;
	self.usernameLabel = nil;
	self.scoreLabel = nil;
	self.selectUserWidget = nil;
	self.editButton = nil;
	[super dealloc];
}

- (void)popBackToMe
{
	[[self navigationController] popToViewController:self animated:YES];
}

- (void)dismiss
{
	if (!hasBeenDismissed)
	{
		[OpenFeint allowErrorScreens:YES];
		[OpenFeint dismissRootControllerOrItsModal];

		hasBeenDismissed = YES;		
		
		mOnCompletionDelegate.invoke();
	}
}


- (void)onBootstrapFailure
{
	OFDeadEndErrorController* errorScreen = (OFDeadEndErrorController*)OFControllerLoader::load(@"DeadEndError");

	[self hideLoadingScreen];
	errorScreen.message = OFLOCALSTRING(@"OpenFeint was unable to log you in at this time.  Some features will be unavailable until the next time you are online.");
	[[self navigationController] pushViewController:errorScreen animated:YES];
}


- (void)continueFlow
{
	[self hideLoadingScreen];

	if ([OpenFeint hasBootstrapCompleted]) {
		OFLinkSocialNetworksController* controller = (OFLinkSocialNetworksController*)OFControllerLoader::load(@"LinkSocialNetworks");
		[controller setCompleteDelegate:mOnCompletionDelegate];
		[self.navigationController pushViewController:controller animated:YES];
	} else {
		// Would like to be sure this case cannot happen any more and replace with assert hasBootstrapCompleted.
		[self dismiss];
	}
}


- (IBAction)_ok
{
	[self continueFlow];
}


- (IBAction)_thisIsntMe
{
	OFOpenFeintAccountLoginController* accountFlowController = (OFOpenFeintAccountLoginController*)OFControllerLoader::load(@"OpenFeintAccountLogin");
	[accountFlowController setCancelDelegate:OFDelegate(self, @selector(popBackToMe))];
	[accountFlowController setCompletionDelegate:OFDelegate(self, @selector(continueFlow))];
	[[self navigationController] pushViewController:accountFlowController animated:YES];
}

- (IBAction)_edit
{
    OFLOCALIZECOMMENT("The 'Edit' is used as a comparision option")
	if ([[editButton currentTitle] isEqualToString:OFLOCALSTRING(@"Edit")])
	{
		[editButton setTitle:OFLOCALSTRING(@"Done") forState:UIControlStateNormal];
		[editButton setTitle:OFLOCALSTRING(@"Done") forState:UIControlStateHighlighted];		
		[selectUserWidget setEditing:YES];
	}
	else
	{
		[editButton setTitle:OFLOCALSTRING(@"Edit") forState:UIControlStateNormal];
		[editButton setTitle:OFLOCALSTRING(@"Edit") forState:UIControlStateHighlighted];		
		[selectUserWidget setEditing:NO];
	}		
}

- (void)setCompleteDelegate:(OFDelegate&)completeDelegate
{
	mOnCompletionDelegate = completeDelegate;
}

- (void)selectUserWidget:(OFSelectUserWidget*)widget didSelectUser:(OFUser*)user
{
	[OpenFeint setLocalUser:user];
	[OpenFeint doBootstrapAsUserId:user.resourceId
		onSuccess:OFDelegate(self, @selector(continueFlow))
		onFailure:OFDelegate(self, @selector(onBootstrapFailure)) ];
	[self showLoadingScreen];
	
	
#if 1 // DIAG_GetTheMost
//	[self continueFlow];
#else
	[self dismiss];
#endif
}

@end
