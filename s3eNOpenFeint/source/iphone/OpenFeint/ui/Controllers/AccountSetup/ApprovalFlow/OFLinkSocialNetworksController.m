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

#import "OFLinkSocialNetworksController.h"

#import "OFFriendImporter.h"
#import "OFExistingAccountController.h"
#import "OFUserSettingService.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFPresenceService.h"
#import "OpenFeint+GameCenter.h"
#import "OFControllerLoaderObjC.h"
#import "OpenFeint+EventLog.h"
#import "OFDependencies.h"

@implementation OFLinkSocialNetworksController

@synthesize mBtnConnectTwitter, mBtnConnectFacebook;
@synthesize mShareLocationSwitch, mShareOnlineStatusSwitch;
@synthesize mShareLocationOriginalState, mShareOnlineStatusOriginalState;
@synthesize onCompletionInvocation;


static BOOL s_SessionSeenLinkSocialNetworksScreen = NO;


+ (BOOL)hasSessionSeenLinkSocialNetworksScreen{
	return s_SessionSeenLinkSocialNetworksScreen;
}


+ (void)invalidateSessionSeenLinkSocialNetworksScreen{
	s_SessionSeenLinkSocialNetworksScreen = NO;
}


#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	OFUserDistanceUnitType userDistanceUnit = [OpenFeint userDistanceUnit];
	
	self.mShareLocationOriginalState		= (userDistanceUnit != kDistanceUnitNotAllowed);
	self.mShareOnlineStatusOriginalState	= [OpenFeint loggedInUserSharesOnlineStatus];
	
    mAppNameLabel.text = [NSString stringWithFormat:@"Now Playing %@", [OpenFeint applicationDisplayName]];
	
	self.mBtnConnectTwitter.enabled = ![OpenFeint loggedInUserHasTwitterCredential];
	self.mBtnConnectFacebook.enabled = ![OpenFeint loggedInUserHasFbconnectCredential];
	self.mShareLocationSwitch.on		= self.mShareLocationOriginalState;
	self.mShareOnlineStatusSwitch.on	= self.mShareOnlineStatusOriginalState;
	
	if (![OpenFeint allowLocationServices])
	{
		self.mShareLocationSwitch.on = NO;
		self.mShareLocationSwitch.enabled = NO;
	}
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	s_SessionSeenLinkSocialNetworksScreen = YES;
	[OFExistingAccountController customAnimateNavigationController:[self navigationController] animateIn:NO];
    
    if (![OpenFeint isLargeScreen]) {
        // adill hack: force this view to be full screen. in 2.x animating out the navbar just drags the view up.
        // normally this is handled by OFFramedNavigationController -- but this is part of the intro flow which
        // is NOT using that! it really should be...
        CGRect frame = [[UIScreen mainScreen] bounds];
        if ([OpenFeint isInLandscapeMode])
        {
            float temp = frame.size.height;
            frame.size.height = frame.size.width;
            frame.size.width = temp;
        }
        self.view.frame = frame;        
    }
    mIsImportingSocialNetwork = NO;
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[OFExistingAccountController customAnimateNavigationController:[self navigationController] animateIn:YES];
	[super viewDidDisappear:animated];
}

#pragma mark IBActions

- (IBAction)onImportFromTwitter
{
	if (!mIsImportingSocialNetwork) {
        mIsImportingSocialNetwork = YES;
        [mImporter importFromTwitter];
    }

}

- (IBAction)onImportFromFacebook
{
	if (!mIsImportingSocialNetwork) {
        mIsImportingSocialNetwork = YES;
        [mImporter importFromFacebook];
    }
}

- (IBAction)onSkip
{
#if 1 // DIAG_GetTheMost
	if ( self.mShareLocationSwitch.on != self.mShareLocationOriginalState){
		[OFUserSettingService setUserSettingWithKey:@"location" toBoolValue:self.mShareLocationSwitch.on onSuccessInvocation:nil onFailureInvocation:nil];
		if (self.mShareLocationSwitch.on){
			[OpenFeint setUserDistanceUnit: kDistanceUnitNotDefined];
		}else{
			[OpenFeint setUserDistanceUnit: kDistanceUnitNotAllowed];
		}
	}
	
	if ( self.mShareOnlineStatusSwitch.on != self.mShareOnlineStatusOriginalState){
		[OFUserSettingService setUserSettingWithKey:@"presence" toBoolValue:self.mShareOnlineStatusSwitch.on onSuccessInvocation:nil onFailureInvocation:nil];
		if (!self.mShareOnlineStatusSwitch.on)
		{
			[[OFPresenceService sharedInstance] disconnect];
		}
	}
	
	// The flag that allows the LinkSocialNetworks screen (aka GetTheMost) can now be dismissed.
	[OpenFeint setDoneWithGetTheMost:YES];
#endif

	if([OpenFeint isUsingGameCenter]) {
        OFViewController* controller = (OFViewController*)[[OFControllerLoaderObjC loader] load:@"GameCenterIntegration"];// load(@"GameCenterIntegration");
//        [controller setCompleteDelegate:mOnCompletionDelegate];
        [[self navigationController] pushViewController:controller animated:YES];
    }
    else {
        [OpenFeint startLocationManagerIfAllowed];
        [OpenFeint allowErrorScreens:YES];
        [OpenFeint dismissRootControllerOrItsModal];
    }
	
    [self.onCompletionInvocation invoke];
//	mOnCompletionDelegate.invoke();

    [[OpenFeint eventLog] logEventWithActionKey:@"enabled_of" logName:@"client_sdk" parameters:nil];
}


//- (void)setCompleteDelegate:(OFDelegate&)completeDelegate
//{
//	mOnCompletionDelegate = completeDelegate;
//}


#pragma mark Boilerplate

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self != nil)
	{
		mImporter = [[OFFriendImporter friendImporterWithController:self] retain];
	}
	
	return self;
}

- (void)dealloc
{
    self.onCompletionInvocation = nil;
	OFSafeRelease(mAppNameLabel);
	[mImporter controllerDealloced];
	OFSafeRelease(mImporter);
	[super dealloc];
}

@end

