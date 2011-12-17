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

#import "OFUsersCredentialCell.h"
#import "UIView+OpenFeint.h"
#import "OFUsersCredential.h"
#import "OFTableSequenceControllerHelper.h"
#import "OFUsersCredentialService.h"
#import "OFImageLoader.h"
#import "OFDependencies.h"

typedef struct OFKnownCredential
{
    NSString* credentialType;
    NSString* imageName;
    NSString* controllerName;
    NSString* labelText;
} OFKnownCredential;

static OFKnownCredential sKnownCredentials[] = 
{
    {@"twitter", @"OpenFeintAccountSetupTwitterConnectButton.png", @"TwitterAccountLogin", nil},
    {@"fbconnect", @"OpenFeintAccountSetupFBConnectButton.png", @"FacebookAccountLogin", nil},
    {@"http_basic", nil, @"OFHttpCredentialCreate", OFLOCALSTRING(@"Create New Password")},
};

@implementation OFUsersCredentialCell

@synthesize owner;

+(OFKnownCredential*)getKnownCredential:(NSString*)credentialName
{
	for (unsigned int i = 0; i < sizeof(sKnownCredentials) / sizeof(OFKnownCredential); i++)
	{
		if ([credentialName isEqualToString:sKnownCredentials[i].credentialType])
		{
			return &sKnownCredentials[i];
		}
	}
	return NULL;
}

+ (NSString*)getCredentialImage:(NSString*)credentialName
{
	OFKnownCredential* knownCredential = [OFUsersCredentialCell getKnownCredential:credentialName];
	return knownCredential ? knownCredential->imageName : nil;
}

+ (NSString*)getCredentialControllerName:(NSString*)credentialName
{
	OFKnownCredential* knownCredential = [OFUsersCredentialCell getKnownCredential:credentialName];
	return knownCredential ? knownCredential->controllerName : nil;
}

+ (NSString*)getCredentialCellText:(NSString*)credentialName
{
	OFKnownCredential* knownCredential = [OFUsersCredentialCell getKnownCredential:credentialName];
	return knownCredential ? knownCredential->labelText : nil;
}

- (void)onResourceChanged:(OFResource*)resource
{	
	OFUsersCredential* credential = (OFUsersCredential*)resource;
	UIImageView* credentialImageView = (UIImageView*)[self findViewByTag:1];
	NSString* imageName = [OFUsersCredentialCell getCredentialImage:credential.credentialType];
	credentialImageView.image = imageName ? [OFImageLoader loadImage:imageName] : nil;
	UILabel* credentialLabel = (UILabel*)[self findViewByTag:2];
	NSString* credentialText = [OFUsersCredentialCell getCredentialCellText:credential.credentialType];
	credentialLabel.text = credentialText;
	credentialLabel.hidden = credentialText == nil;
}

- (void)dealloc
{
	[super dealloc];
}

@end
