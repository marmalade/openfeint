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
#import "OFChatRoomDefinitionCell.h"
#import "OFViewHelper.h"
#import "OFChatRoomDefinition.h"
#import "OFImageLoader.h"

@implementation OFChatRoomDefinitionCell

- (void)onResourceChanged:(OFResource*)resource
{
	OFChatRoomDefinition* chatRoom = (OFChatRoomDefinition*)resource;
	
	UILabel* nameLabel = (UILabel*)OFViewHelper::findViewByTag(self, 1);
	nameLabel.text = chatRoom.roomName;
	
	UIImageView* typeIcon = (UIImageView*)OFViewHelper::findViewByTag(self, 5);
	typeIcon.image = [OFChatRoomDefinitionCell getChatIconForChatType:chatRoom.roomType full:NO];
	
}

+ (UIImage*)getChatIconForChatType:(NSString*)chatType full:(BOOL)full
{
	NSString* suffix = full ? @"Full" : @"";
	if ([chatType isEqualToString:[OFChatRoomDefinition getDeveloperRoomTypeId]])
	{
		return [OFImageLoader loadImage:[NSString stringWithFormat:@"OFIconChat%@.png", suffix]];
	}
	else if ([chatType isEqualToString:[OFChatRoomDefinition getApplicationRoomTypeId]])
	{
		return [OFImageLoader loadImage:[NSString stringWithFormat:@"OFIconChat%@.png", suffix]];
	}
	else
	{
		return [OFImageLoader loadImage:[NSString stringWithFormat:@"OFIconChat%@.png", suffix]];
	}
}

@end
