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

#pragma once

enum ESocialNetworkCellType
{
	ESocialNetworkCellType_INVALID = -2,
    ESocialNetworkCellType_NONE = -1,
	ESocialNetworkCellType_FACEBOOK = 0,
	ESocialNetworkCellType_TWITTER,
	ESocialNetworkCellType_COUNT,
};

@interface OFSocialNotification : NSObject {
	NSString* text;
	NSString* imageType;
	NSString* imageIdentifier;
	NSString* imageUrl;
	NSString* url;
	NSMutableArray* sendToNetworks;
}

@property(nonatomic, retain) NSString* text;
@property(nonatomic, retain) NSString* imageType;
@property(nonatomic, retain) NSString* imageIdentifier;
@property(nonatomic, retain) NSString* imageUrl;
@property(nonatomic, retain) NSString* url;
@property(nonatomic, retain) NSMutableArray* sendToNetworks;

- (id)initWithText:(NSString*)_text;
- (id)initWithText:(NSString*)_text imageNamed:(NSString*)_imageName;
- (id)initWithText:(NSString*)_text imageNamed:(NSString*)_imageName linkedUrl:(NSString*)_url;
- (id)initWithText:(NSString*)_text imageType:(NSString*)_imageType imageId:(NSString*)_imageId;
- (id)initWithText:(NSString*)_text imageType:(NSString*)_imageType imageId:(NSString*)_imageId linkedUrl:(NSString*)_url;

- (void)addSendToNetwork:(ESocialNetworkCellType)network;
- (void)clearSendToNetworks;

@end
