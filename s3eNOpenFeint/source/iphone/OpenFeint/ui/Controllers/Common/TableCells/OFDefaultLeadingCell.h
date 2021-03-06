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

#import "OFTableCellHelper.h"
@class OFImageView;

@class OFUser;

@interface OFDefaultLeadingCell : OFTableCellHelper
{
	UILabel* headerLabel;
	UIView* headerContainerView;
	OFImageView* leftIconView;
	OFImageView* rightIconView;
	OFImageView* secondFromRightIconView;
	
	id mCallbackTarget;
	SEL mLeftIconSelector;
    SEL mRightIconSelector;
}

@property (nonatomic, retain) IBOutlet UILabel* headerLabel;
@property (nonatomic, retain) IBOutlet UIView* headerContainerView;
@property (nonatomic, retain) IBOutlet OFImageView* leftIconView;
@property (nonatomic, retain) IBOutlet OFImageView* rightIconView;
@property (nonatomic, retain) IBOutlet OFImageView* secondFromRightIconView;

- (IBAction)onClickedLeftIcon;
- (IBAction)onClickedRightIcon;
- (IBAction)onClickedSecondFromRightIcon;

- (void)setCallbackTarget:(id)target;
- (void)setLeftIconSelector:(SEL)leftIconSelector;
- (void)setRightIconSelector:(SEL)rightIconSelector;

- (void)enableLeftIconView;
- (void)enableLeftIconViewWithImageUrl:(NSString*)imageUrl andDefaultImage:(NSString*)defaultImageName;
- (void)enableRightIconView;
- (void)enableSecondFromRightIconView;
- (void)enableBothRightIconViews;
- (void)disableRightIconView;
- (void)disableSecondFromRightIconView;
- (void)disableBothRightIconViews;
- (void)populateRightIconsAsComparison:(OFUser*)pageOwner;
- (void)populateRightIconsAsComparisonWithImageUrl:(NSString*)imageUrl;

@end
