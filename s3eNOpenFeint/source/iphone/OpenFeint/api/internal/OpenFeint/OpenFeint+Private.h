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

#import "OpenFeint.h"
#import "OFNotificationStatus.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OFReachability.h"
#import "OFInvocation.h"

@class OFActionRequest;
@class MPOAuthAPIRequestLoader;
@class OFRequestHandle;
struct sqlite3;

@interface OpenFeint (Private) <OFReachabilityObserver>

+ (BOOL)hasBootstrapCompleted;
+ (void)invalidateBootstrap;

+ (OpenFeint*) sharedInstance;
+ (void) createSharedInstance;
+ (void) destroySharedInstance;
+ (id<OpenFeintDelegate>)getDelegate;
+ (id<OFNotificationDelegate>)getNotificationDelegate;
+ (id<OFChallengeDelegate>)getChallengeDelegate;
+ (id<OFBragDelegate>)getBragDelegate;
+ (UIInterfaceOrientation)getDashboardOrientation;
+ (BOOL)isInLandscapeMode;
+ (BOOL)isInLandscapeModeOniPad;
+ (BOOL)isLargeScreen;
+ (CGRect)getDashboardBounds;

+ (void)loginWasAborted:(BOOL)sslError;
+ (void)loginShowNotifications;
+ (void)loginGameCenterCheck;

+ (void)launchLoginFlowThenDismiss;
+ (void)launchLoginFlowToDashboard;
+ (void)launchLoginFlowForRequest:(OFActionRequest*)request;
+ (void)doBootstrapAsNewUserOnSuccess:(OFInvocation*)chainedOnSuccess onFailure:(OFInvocation*)chainedOnFailure;
+ (void)doBootstrapAsUserId:(NSString*)userId onSuccess:(OFInvocation*)chainedOnSuccess onFailure:(OFInvocation*)chainedOnFailure;
+ (void)addBootstrapInvocations:(OFInvocation*)onSuccess onFailure:(OFInvocation*)onFailure;
+ (BOOL)isSuccessfullyBootstrapped;
+ (void)presentConfirmAccountModalInvocation:(OFInvocation*)onCompletionInvocation useModalInDashboard:(BOOL)useModalInDashboard;

+ (void)abortBootstrap;

+ (UIWindow*)getTopApplicationWindow;
+ (UIView*) getTopLevelView;
+ (OFRootController*)getRootController;
+ (UINavigationController*)getActiveNavigationController;
+ (void)reloadInactiveTabBars;
+ (BOOL)isShowingFullScreen;
+ (BOOL)isDashboardHubOpen;
+ (void)presentModalOverlay:(UIViewController*)modal;
+ (void)presentModalOverlay:(UIViewController*)modal opaque:(BOOL)isOpaque;
+ (void)presentRootControllerWithModal:(UIViewController*)modal;
+ (void)presentRootControllerWithTabbedDashboard:(NSString*)controllerName;
+ (void)presentRootControllerWithTabbedDashboard:(NSString*)controllerName pushControllers:(NSArray*)pushControllers;
+ (void)launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName;
+ (void)launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName andController:(NSString*)controller;
+ (void)launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName andControllers:(NSArray*)controllers;
+ (void)dismissRootController;
+ (void)dismissRootControllerOrItsModal;
+ (void)destroyDashboard;

+ (void)updateApplicationBadge;

+ (void)allowErrorScreens:(BOOL)allowed;
+ (BOOL)areErrorScreensAllowed;
+ (BOOL)isShowingErrorScreenInNavController:(UINavigationController*)navController;

+ (void)displayUpgradeRequiredErrorMessage:(NSData*)data;
+ (void)displayErrorMessage:(NSString*)message;
+ (void)displayErrorMessageAndOfflineButton:(NSString*)message;
+ (void)displayServerMaintenanceNotice:(NSData*)data;

+ (void)dashboardWillAppear;
+ (void)dashboardDidAppear;
+ (void)dashboardWillDisappear;
+ (void)dashboardDidDisappear;

+ (void)reserveMemory;
+ (void)releaseReservedMemory;

+ (void)setPollingFrequency:(NSTimeInterval)frequency;
+ (void)setPollingToDefaultFrequency;
+ (void)stopPolling;
+ (void)forceImmediatePoll;
+ (void)clearPollingCacheForClassType:(Class)resourceClassType;

+ (void)switchToOnlineDashboard;
+ (void)switchToOfflineDashboard;

+ (void)setupOfflineDatabase;
+ (void)teardownOfflineDatabase;
+ (struct sqlite3*)getOfflineDatabaseHandle;
+ (struct sqlite3*)getBootstrapOfflineDatabaseHandle;

+ (OFProvider*)provider;
+ (OFSession*)session;
+ (BOOL)isTargetAndSystemVersionThreeOh;
+ (BOOL)isTargetAndSystemVersionFourOh;

+ (BOOL)developerAllowsUserGeneratedContent;
+ (BOOL)allowUserGeneratedContent;
+ (BOOL)allowLocationServices;

+ (ENotificationPosition)notificationPosition;
// To Be Deleted
+ (BOOL)invertNotifications;

+ (void) startLocationManagerIfAllowed;
+ (CLLocation*) getUserLocation;
+ (void) setUserLocation:(OFLocation*)userLoc;

+ (NSString*)gameSpecificDeviceIdentifier;

+ (OFRequestHandle*)getImageFromUrl:(NSString*)url forModule:(id)module onSuccess:(OFInvocation*)success onFailure:(OFInvocation*)failure;

- (void)_rotateDashboardFromOrientation:(UIInterfaceOrientation)oldOrientation toOrientation:(UIInterfaceOrientation)newOrientation;

+ (NSBundle*)getResourceBundle;

+ (BOOL)isApprovalScreenOpen;

@end
