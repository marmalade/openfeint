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
#import "OFGameDiscoveryNewsItemCell.h"
#import "OFGameDiscoveryNewsItem.h"
#import "OFImageView.h"

@implementation OFGameDiscoveryNewsItemCell

@synthesize iconFrame, iconView, titleLabel, subtitleLabel;

- (void)onResourceChanged:(OFResource*)resource
{
    self.iconFrame.image = [self.iconFrame.image stretchableImageWithLeftCapWidth:21.f topCapHeight:19.f];
    
	OFGameDiscoveryNewsItem* newsItem = (OFGameDiscoveryNewsItem*)resource;
	self.iconView.imageUrl = newsItem.iconUrl;
	self.titleLabel.text = newsItem.title;
	self.subtitleLabel.text = newsItem.subtitle;
}

- (void)dealloc
{
    self.iconFrame = nil;
	self.iconView = nil;
	self.titleLabel = nil;
	self.subtitleLabel = nil;
	
	[super dealloc];
}

@end
