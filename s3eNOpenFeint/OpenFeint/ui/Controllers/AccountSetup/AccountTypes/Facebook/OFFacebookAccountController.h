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

#import "OFAccountSetupBaseController.h"
#import "FBConnect.h"
#import "OFFBDialog.h"

@interface OFFacebookAccountController : OFAccountSetupBaseController<FBSessionDelegate, FBDialogDelegate, FBRequestDelegate>
{
@private
	FBUID fbuid;
	FBSession* fbSession;
	NSURL* urlToLaunch;
	UIImageView* fbLoggedInStatusImageView;
	UIInterfaceOrientation orientationBeforeFix;
	UIView* invisibleKeyboardTrap;
	BOOL getPostingPermission;
	
@package
	OFFBDialog* loginDialog;
	bool skipLoginOnAppear;
	bool updateServerPostingPermissions;
}

- (void)promptToLogin;
- (void)closeLoginDialog;

//Override
- (NSString*)_getFormSubmissionUrl;
- (void)_session:(FBSession*)session didLogin:(FBUID)uid;

@property (nonatomic, assign) FBUID fbuid;
@property (nonatomic, retain) NSURL* urlToLaunch;
@property (nonatomic, retain) IBOutlet UIImageView* fbLoggedInStatusImageView;
@property (nonatomic, retain) FBSession* fbSession;
@property (nonatomic, assign) BOOL getPostingPermission;
@end
