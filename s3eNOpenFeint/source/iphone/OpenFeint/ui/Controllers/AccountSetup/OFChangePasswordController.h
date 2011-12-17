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
#import "OFProfileFrame.h"

@interface OFChangePasswordController : OFFormControllerHelper<OFProfileFrame>
{
@private
	UITextField* oldPasswordField;
	UITextField* passwordField;
	UITextField* passwordConfirmationField;

	NSString* oldPassword;
	NSString* password;
	NSString* passwordConfirmation;
}

@property (nonatomic, retain) IBOutlet UITextField* oldPasswordField;
@property (nonatomic, retain) IBOutlet UITextField* passwordField;
@property (nonatomic, retain) IBOutlet UITextField* passwordConfirmationField;

@end
