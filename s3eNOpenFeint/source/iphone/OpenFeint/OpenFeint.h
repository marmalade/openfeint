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
#import "OFInvocation.h"
#import "OFDelegatesContainer.h"
#import "OpenFeintSettings.h"
#import "OFLocation.h"
#import "OFSessionObserver.h"

@class OFProvider;
@class OFPoller;
@class OFRootController;
@class OFUser;
@class OFSession;
@class OFGameBar;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///
/// Public OpenFeint API
///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Defines where notifications can appear on the screen.  4 Positions are available for ipad, and 2 for iphone.  For
/// iphone use ENotificationPosition_TOP and ENotificationPosition_BOTTOM.  For iPad use ENotificationPosition_TOP_LEFT, 
/// ENotificationPosition_BOTTOM_LEFT, ENotificationPosition_BOTTOM_RIGHT, ENotificationPosition_TOP_RIGHT.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
typedef enum ENotificationPosition
{
	ENotificationPosition_TOP = 0,
	ENotificationPosition_BOTTOM,
	ENotificationPosition_TOP_LEFT = ENotificationPosition_TOP,
	ENotificationPosition_BOTTOM_LEFT = ENotificationPosition_BOTTOM,
	ENotificationPosition_TOP_RIGHT,
	ENotificationPosition_BOTTOM_RIGHT,
	ENotificationPosition_COUNT,
} ENotificationPosition;

@interface OpenFeint : NSObject<UIActionSheetDelegate, CLLocationManagerDelegate, OFSessionObserver>
{
@protected
	OFDelegatesContainer* mDelegatesContainer;
	id<OpenFeintDelegate> mLaunchDelegate;
	BOOL mIsDashboardDismissing;
	UIWindow* mPresentationWindow;
	UIViewController* mQueuedRootModal;
	BOOL mIsQueuedModalAnOverlay;
	OFRootController* mOFRootController;
	NSString* mDisplayName;
	NSString* mShortDisplayName;
	OFProvider* mProvider;
	OFSession* mSession;
	OFPoller* mPoller;
	UIInterfaceOrientation mPreviousOrientation;
	UIInterfaceOrientation mDashboardOrientation;
	ENotificationPosition mNotificationPosition;
	BOOL mPreviousStatusBarHidden;
	NSTimeInterval mPollingFrequencyBeforeResigningActive;
	struct sqlite3* mOfflineDatabaseHandle;
	struct sqlite3* mBootstrapOfflineDatabaseHandle;
	BOOL mIsErrorPending;
	BOOL mPushNotificationsEnabled;
    BOOL mRequireOnlineStatus;
    BOOL mPromptUserForLogin;
    NSMutableSet* mBootstrapSuccessInvocations;
    NSMutableSet* mBootstrapFailureInvocations;
    
	BOOL mForceCreateAccountOnBootstrap;
	BOOL mSuccessfullyBootstrapped;
	BOOL mAllowErrorScreens;
	BOOL mIsShowingOverlayModal;
	
	void* mReservedMemory;
	
	OFLocation* mLocation;
	OFUser* mCachedLocalUser;
    NSString* mProductKey;
    
    BOOL mIsUsingGameCenter;
	BOOL mDashboardVisible;
    BOOL mForceUserCheckOnBootstrap;
    BOOL mSnapDashboardRotation;
    BOOL mUseSandboxPushNotificationServer;
    BOOL mApprovalScreenOpen;
    
	BOOL mDeveloperDisabledUGC;
    BOOL mDeveloperDisabledLocationServices;

    struct {
		unsigned int isConfirmAccountFlowActive:1;
		unsigned int hasDeferredLoginDelegate:1;
		unsigned int isOpenFeintDashboardInOnlineMode:1;
		unsigned int isBootstrapInProgress:1;
    } _openFeintFlags;
	
	BOOL appNeedsGetLocationOnForeground;
}
@property (nonatomic, retain) NSString* mProductKey;
@property (nonatomic) BOOL mForceUserCheckOnBootstrap;
@property (nonatomic) BOOL mUseSandboxPushNotificationServer;

////////////////////////////////////////////////////////////
///
/// @param productKey is copied. This is your unique product key you received when registering your application.
/// @param productSecret is copied. This is your unique product secret you received when registering your application.
/// @param displayName is copied.
/// @param settings is copied. The available settings are defined as OpenFeintSettingXXXXXXXXXXXX. See OpenFeintSettings.h
/// @param delegatesContainer is retained but none of the delegates in the container are retained. 
///
/// @note This will begin the application authorization process.
///
////////////////////////////////////////////////////////////
+ (void) initializeWithProductKey:(NSString*)productKey 
						andSecret:(NSString*)secret
				   andDisplayName:(NSString*)displayName
					  andSettings:(NSDictionary*)settings 
					 andDelegates:(OFDelegatesContainer*)delegatesContainer;

////////////////////////////////////////////////////////////
///
/// Shuts down OpenFeint
///
////////////////////////////////////////////////////////////
+ (void) shutdown;

////////////////////////////////////////////////////////////
///
/// Launches the OpenFeint Dashboard view at the top of your application's keyed window.
///
/// @note:	If the player has not yet authorized your app, they will be prompted to setup an 
///			account or authorize your application before accessing the OpenFeint dashboard
///
////////////////////////////////////////////////////////////
+ (void) launchDashboard;

////////////////////////////////////////////////////////////
///
/// @see launchDashboard
/// 
/// @param delegate The delegate that is used for this launch. The original delegate will be restored
///					after dismissing the dashboard for use in future calls to launchDashboard.
///
////////////////////////////////////////////////////////////
+ (void) launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate;

////////////////////////////////////////////////////////////
///
/// Removes the OpenFeint Dashboard from your application's keyed window.
///
////////////////////////////////////////////////////////////
+ (void) dismissDashboard;

////////////////////////////////////////////////////////////
///
/// Sets what orientation the dashboard and notifications will show in.
///
////////////////////////////////////////////////////////////
+ (void) setDashboardOrientation:(UIInterfaceOrientation)orientation;

////////////////////////////////////////////////////////////
///
/// @return The version of the OpenFeint client library in use.
///
////////////////////////////////////////////////////////////
+ (NSUInteger)versionNumber;

////////////////////////////////////////////////////////////
///
/// @return The release Version String of the OpenFeint client library in use.
///
////////////////////////////////////////////////////////////
+ (NSString*)releaseVersionString;

////////////////////////////////////////////////////////////
///
/// If your application is using a non-portrait layout, you must invoke and return this instead 
/// of directly returning your supported orientations from shouldAutorotateToInterfaceOrientation.
///
/// For example:
///		<br/>const unsigned int numOrientations = 2;
///		<br/>UIInterfaceOrientation myOrientations[numOrientations] = { UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight };
///		<br/>return [OpenFeint shouldAutorotateToInterfaceOrientation:interfaceOrientation withSupportedOrientations:myOrientations andCount:numOrientations];
///
////////////////////////////////////////////////////////////
+(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation withSupportedOrientations:(UIInterfaceOrientation*)nullTerminatedOrientations andCount:(unsigned int)numOrientations;

////////////////////////////////////////////////////////////
///
/// If OpenFeintSettingEnablePushNotifications is set to true, these functions MUST be called
/// from the application delegates
/// - application:didRegisterForRemoteNotificationsWithDeviceToken:
/// - application:didFailToRegisterForRemoteNotificationsWithError:
/// - application:didReceiveRemoteNotification:
///
////////////////////////////////////////////////////////////
+ (void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
+ (void)applicationDidFailToRegisterForRemoteNotifications;
/// Returns whether or not OpenFeint responded to the notification parameters
+ (BOOL)applicationDidReceiveRemoteNotification:(NSDictionary *)userInfo;

////////////////////////////////////////////////////////////
///
/// Call this method from application:didFinishLaunchingWithOptions: after OpenFeint has been initialized
/// This MUST be implemented for challenges to work through remote notifications.
///
/// Returns whether or not OpenFeint responded to the launch options
///
////////////////////////////////////////////////////////////
+ (BOOL)respondToApplicationLaunchOptions:(NSDictionary*)launchOptions;

////////////////////////////////////////////////////////////
///
/// Returns whether or not the user has enabled OpenFeint for this game.
///
////////////////////////////////////////////////////////////
+ (BOOL)hasUserApprovedFeint;

////////////////////////////////////////////////////////////
///
/// Call this method ONLY if overriding the OpenFeint disclosure screen via the delegate method
/// -(BOOL)willLaunchOpenFeintDisclosureScreen. You must pass in whether or not the user has chosen
/// to use OpenFeint in this application. You may optionally pass in a delegate that gets  called
/// once the setup process is complete
///
////////////////////////////////////////////////////////////
+ (void)userDidApproveFeint:(BOOL)approved;
+ (void)userDidApproveFeint:(BOOL)approved accountSetupCompleteInvocation:(OFInvocation*)accountSetupCompleteInvocation;

////////////////////////////////////////////////////////////
///
/// The OpenFeint Approval flow is launched automatically on initialization (and dashboard launch if user hasn't approved OpenFeint). 
/// Only call this when the user requests to use OpenFeint features and [OpenFeint hasUserApprovedFeint] returns NO.
/// An example is when a user wants to create a challenge.
///
////////////////////////////////////////////////////////////
+ (void)presentUserFeintApprovalModalInvocation:(OFInvocation*)approvedInvocation deniedInvocation:(OFInvocation*)deniedInvocation;

////////////////////////////////////////////////////////////
///
/// Returns whether or not the game is connected to the OpenFeint server
///
////////////////////////////////////////////////////////////
+ (BOOL)isOnline;

////////////////////////////////////////////////////////////
///
/// Attempt to login to OpenFeint with the specified user. If the login attempt succeeds your onSuccess delegate will be invoked and
/// it the attempt fails your onFailure delegate will be invoked.
///
////////////////////////////////////////////////////////////
+ (void)loginWithUserId:(NSString*)openFeintUserId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;

////////////////////////////////////////////////////////////
///
/// Returns a string to use as a device identifier
/// This string is currently the uniqueIdentifier of device, but it will be swapped out later
+ (NSString*)uniqueDeviceId;


////////////////////////////////////////////////////////////
/// @internal
////////////////////////////////////////////////////////////
@property (nonatomic, assign) BOOL dashboardVisible;

@end
