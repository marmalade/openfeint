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

#import "OFViewController.h"
#import "OFLoadingController.h"
#import "OFFramedNavigationController.h"
#import "OFViewHelper.h"
#import "UIViewController+TabBar.h"
#import "OFTabBarItem.h"
#import "OpenFeint+Private.h"
#import "OFIntroNavigationController.h"
#import "UIViewController+OpenFeint.h"

@implementation OFViewController

@synthesize owningTabBarItem;

- (void)viewDidLoad
{
	[super viewDidLoad];

	UIScrollView* topScrollView = OFViewHelper::findFirstScrollView(self.view);
	CGSize contentSize = OFViewHelper::sizeThatFitsTight(topScrollView);
	contentSize.height += 10.f;
	[topScrollView setContentSize:contentSize];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    // If this is owned by a webnav controller, then it manages the loading indicator instead
    if (!self.webNavController)
    {
        [self hideLoadingScreen];
    }
}

- (void)showLoadingScreenWithMessage:(NSString*)message
{
	OFSafeRelease(mLoadingScreen);
	mLoadingScreen = [[OFLoadingController loadingControllerWithText:message] retain];
	[self.view addSubview:mLoadingScreen.view];
}

- (void)hideLoadingScreen
{
	OFNavigationController* navController = (OFNavigationController*)self.navigationController;
	if(navController)
	{
		OFAssert([navController isKindOfClass:[OFNavigationController class]], "only use OFNavigationControllers");
		[navController hideLoadingIndicator];
	}
}

- (void)showLoadingScreen
{
	OFNavigationController* navController = (OFNavigationController*)self.navigationController;
	if(navController)
	{
		OFAssert([navController isKindOfClass:[OFNavigationController class]], "only use OFNavigationControllers");
		[navController showLoadingIndicator];
	}
}

- (NSString*)getLoadingScreenText
{
	return OFLOCALSTRING(@"Downloading");
}

- (void)setBadgeValue:(NSString*)aBadgeValue
{
	if (self.navigationController)
		[self.navigationController setBadgeValue:aBadgeValue];
	else
		[super setBadgeValue:aBadgeValue];
}

- (void)dealloc
{
	OFSafeRelease(mLoadingScreen);
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == [OpenFeint getDashboardOrientation];
}

- (OFUser*)getPageContextUser
{
	if ([self.navigationController isKindOfClass:[OFFramedNavigationController class]])
	{
		OFFramedNavigationController* framedNavController = (OFFramedNavigationController*)self.navigationController;
		return framedNavController.currentUser;
	}
	else
	{
		return nil;
	}
}

- (BOOL)isCurrentlyInIntroFlow
{
    if (self.navigationController && self.navigationController == [OFIntroNavigationController activeIntroNavigationController].navController)
        return YES;
    else
        return NO;
}

@end
