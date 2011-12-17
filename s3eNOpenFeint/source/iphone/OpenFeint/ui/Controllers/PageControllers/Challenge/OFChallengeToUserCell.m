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

#import "OFChallengeToUserCell.h"
#import "UIView+OpenFeint.h"
#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFChallengeDefinition.h"
#import "OFImageView.h"
#import "OFUser.h"
#import "OFImageLoader.h"

#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

static const int kChallengerPictureTag = 4;
static const int kStatusIconTag = 5;
static const int kDirectionIconTag = 1;
static const int kTitleTag = 2;
static const int kUserNameTag = 8;
static const int kChallengeDescriptionTag = 3;
static const int kNumAttemptsTag = 9;

@implementation OFChallengeToUserCell

- (void)onResourceChanged:(OFResource*)resource
{
	OFChallengeToUser* userChallenge = (OFChallengeToUser*)resource;
	
	UIImageView* statusIndicator = (UIImageView*)[self findViewByTag:kStatusIconTag];
	UIImageView* directionIndicator = (UIImageView*)[self findViewByTag:kDirectionIconTag];
	statusIndicator.hidden = YES;
	BOOL sentByLocalUser = [userChallenge.challenge.challenger isLocalUser];
	
	directionIndicator.hidden = !sentByLocalUser;
	
	if(userChallenge.isCompleted)
	{
		OFChallengeResult result = userChallenge.result;
		// We always want to display the results in relation to the local user.
		if (![userChallenge.recipient isLocalUser])
		{
			if (result == kChallengeResultRecipientWon)
			{
				result = kChallengeResultRecipientLost;
			}
			else if (result == kChallengeResultRecipientLost)
			{
				result = kChallengeResultRecipientWon;
			}
		}
		statusIndicator.image = [OFImageLoader loadImage:[OFChallengeToUser getChallengeResultIconName:result]];
		statusIndicator.hidden = NO;
	}
	else
	{
		if(sentByLocalUser || userChallenge.hasBeenViewed)
		{
			statusIndicator.hidden = YES;
		}
		else
		{
			statusIndicator.image = [OFImageLoader loadImage:@"OFChallengeIconNew.png"];
			statusIndicator.hidden = NO;

			if (![userChallenge hasDecrementedChallengeCount] && [[OpenFeint clientApplicationId] isEqualToString:[[[userChallenge challenge] challengeDefinition] clientApplicationId]])
			{
				NSInteger unviewed = [OpenFeint unviewedChallengesCount] - 1;
				unviewed = (unviewed < 0) ? 0 : unviewed;
				[OpenFeint setUnviewedChallengesCount:unviewed];
				userChallenge.hasDecrementedChallengeCount = YES;
			}
		}
	}
	
	UILabel	*titleLabel = (UILabel*)[self findViewByTag:kTitleTag];
	titleLabel.text = userChallenge.challenge.challengeDefinition.title;
	
	UILabel *descriptionLabel = (UILabel*)[self findViewByTag:kChallengeDescriptionTag];
	descriptionLabel.text = userChallenge.challenge.userMessage ? userChallenge.challenge.userMessage : userChallenge.challenge.challengeDescription;
	
	OFImageView* challengerProfilePictureView = (OFImageView*)[self findViewByTag:kChallengerPictureTag];
	UILabel	*userNameLabel = (UILabel*)[self findViewByTag:kUserNameTag];
	if (sentByLocalUser)
	{
		userNameLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"To %@"), userChallenge.recipient.name];
		[challengerProfilePictureView useProfilePictureFromUser:userChallenge.recipient];
	}
	else
	{
		userNameLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"From %@"), userChallenge.challenge.challenger.name];
		[challengerProfilePictureView useProfilePictureFromUser:userChallenge.challenge.challenger];
	}
	
}


@end
