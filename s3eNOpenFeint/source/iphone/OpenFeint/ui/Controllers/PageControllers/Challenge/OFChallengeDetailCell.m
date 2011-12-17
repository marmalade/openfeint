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

#import "OFChallengeDetailCell.h"
#import "UIView+OpenFeint.h"
#import "OFChallenge.h"
#import "OFChallengeToUser.h"
#import "OFChallengeDefinition.h"
#import "OFImageView.h"
#import "OFUser.h"
#import "OFImageLoader.h"
#import "OFDependencies.h"

@implementation OFChallengeDetailCell

- (void)onResourceChanged:(OFResource*)resource
{

	OFChallengeToUser* userChallenge = (OFChallengeToUser*)resource;
	
	UILabel* userNameLabel = (UILabel*)[self findViewByTag:2];
	userNameLabel.text = userChallenge.recipient.name;
	
	UILabel* resultLabel = (UILabel*)[self findViewByTag:5];
	if (userChallenge.isCompleted)
	{
		resultLabel.text = userChallenge.formattedResultDescription;
	}
	else
	{
		resultLabel.text = OFLOCALSTRING(@"Challenge not completed yet.");
	}
	
	UILabel* numTriesLabel = (UILabel*)[self findViewByTag:7];
	if (userChallenge.challenge.challengeDefinition.multiAttempt && (userChallenge.attempts > 0))
	{
		numTriesLabel.hidden = NO;
        OFLOCALIZECOMMENT("Plurals")
		NSString* triesText = (userChallenge.attempts > 1) ? OFLOCALSTRING(@"tries") : OFLOCALSTRING(@"try");
		numTriesLabel.text = [NSString stringWithFormat:@"%d %@", userChallenge.attempts, triesText];
	}
	else
	{
		numTriesLabel.hidden = YES;
	}
	
	
	OFImageView* challengerProfilePictureView = (OFImageView*)[self findViewByTag:1];
	[challengerProfilePictureView useProfilePictureFromUser:userChallenge.recipient];
	
	UIImageView* statusIconView = (UIImageView*)[self findViewByTag:4];
	if(userChallenge.isCompleted == YES)
	{
		statusIconView.image = [OFImageLoader loadImage:[OFChallengeToUser getChallengeResultIconName:userChallenge.result]];
		statusIconView.hidden = NO;
	}
	else
	{
		statusIconView.hidden = YES;
	}
}


@end
