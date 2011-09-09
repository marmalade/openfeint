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

#import "OFDependencies.h"
#import "OFChallengeSentCell.h"
#import "OFViewHelper.h"
#import "OFChallenge.h"
#import "OFChallengeDefinition.h"
#import "OFImageView.h"
#import "OFUser.h"
#import "OFImageLoader.h"

namespace 
{
	const int kChallengePictureTag = 1;
	const int kTitleTag = 2;
	const int kDescriptionTag = 3;
}

@implementation OFChallengeSentCell

- (void)onResourceChanged:(OFResource*)resource
{
	OFChallenge* newChallenge = (OFChallenge*)resource;
	
	OFImageView* challengePictureView = (OFImageView*)OFViewHelper::findViewByTag(self, kChallengePictureTag);
	[challengePictureView setDefaultImage:[OFImageLoader loadImage:@"OFMultiPeopleChallengeIcon.png"]];
	challengePictureView.imageUrl = newChallenge.challengeDefinition.iconUrl;
	
	UILabel	*titleLabel = (UILabel*)OFViewHelper::findViewByTag(self, kTitleTag);
	titleLabel.text = newChallenge.challengeDefinition.title;
	
	UILabel *descriptionLabel = (UILabel*)OFViewHelper::findViewByTag(self, kDescriptionTag);
	descriptionLabel.text = newChallenge.challengeDescription;
	
}

@end
