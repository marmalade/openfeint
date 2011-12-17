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

#import "OFAchievementCompareListCell.h"
#import "UIView+OpenFeint.h"
#import "OFAchievement.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OpenFeint+UserOptions.h"
#import "OFDependencies.h"

@implementation OFAchievementCompareListCell

@synthesize	achievementIcon,
            titleLabel,
			firstIconContainer,
			secondIconContainer,
			firstUnlockedIcon,
			secondUnlockedIcon,
			firstGamerScoreContainer,
            secondGamerScoreContainer,
			firstGamerScoreLabel,
            secondGamerScoreLabel;


- (void)onResourceChanged:(OFResource*)resource
{	
	OFAchievement* achievement = (OFAchievement*)resource;

    firstUnlockedIcon.unframed = YES;
    secondUnlockedIcon.unframed = YES;
    [achievementIcon setDefaultImage:[OFImageLoader loadImage:@"OFUnlockedAchievementIconNotSquare.png"]];
    achievementIcon.imageUrl = achievement.iconUrl;

    OFImageView* leftMostLockIcon = secondUnlockedIcon;
    UILabel* leftMostScoreLabel = secondGamerScoreLabel;
    UIView* leftMostIconContainer = secondIconContainer;
    UIView* leftMostScoreContainer = secondGamerScoreContainer;

	if (achievement.comparedToUserId && 
		![achievement.comparedToUserId isEqualToString:@""] && 
		![achievement.comparedToUserId isEqualToString:[OpenFeint lastLoggedInUserId]])
	{
        if (achievement.isUnlockedByComparedToUser)
		{
            firstIconContainer.hidden = YES;
            firstGamerScoreContainer.hidden = NO;
            firstGamerScoreLabel.text = [NSString stringWithFormat:@"%d", achievement.gamerscore];
		}
		else
		{
			firstIconContainer.hidden = NO;
            firstGamerScoreContainer.hidden = YES;
            firstUnlockedIcon.image = [OFImageLoader loadImage:@"OFLockedAchievementIcon.png"];
		}
	}
    else
    {
        secondGamerScoreContainer.hidden = YES;
        secondIconContainer.hidden = YES;

        leftMostLockIcon = firstUnlockedIcon;
        leftMostScoreLabel = firstGamerScoreLabel;
        leftMostIconContainer = firstIconContainer;
        leftMostScoreContainer = firstGamerScoreContainer;
    }
	
	if (achievement.isUnlocked)
	{
		leftMostIconContainer.hidden = YES;
        leftMostScoreContainer.hidden = NO;
        leftMostScoreLabel.text = [NSString stringWithFormat:@"%d", achievement.gamerscore];
	}
	else
	{
		leftMostScoreContainer.hidden = YES;
        leftMostLockIcon.image = [OFImageLoader loadImage:@"OFLockedAchievementIcon.png"];
        leftMostIconContainer.hidden = NO;
	}
    
	CGRect titleFrame = titleLabel.frame;
	titleFrame.size.width = leftMostIconContainer.frame.origin.x - titleFrame.origin.x - 10.f;
	titleLabel.frame = titleFrame;
    
	if (achievement.isSecret && !achievement.isUnlocked)
	{
		titleLabel.text = OFLOCALSTRING(@"Secret");
	}
	else
	{
		titleLabel.text = achievement.title;
	}
	
	CGRect myRect = self.frame;
	myRect.size.height = achievementIcon.frame.size.height + achievementIcon.frame.origin.y + 12;
	self.frame = myRect;
	[self layoutSubviews];
}

- (void)dealloc
{
    self.achievementIcon = nil;
	self.titleLabel = nil;
	self.firstIconContainer = nil;
	self.secondIconContainer = nil;
	self.firstUnlockedIcon = nil;
	self.secondUnlockedIcon = nil;
	self.firstGamerScoreContainer = nil;
	self.secondGamerScoreContainer = nil;
    self.firstGamerScoreLabel = nil;
    self.secondGamerScoreLabel = nil;

	[super dealloc];
}
@end
