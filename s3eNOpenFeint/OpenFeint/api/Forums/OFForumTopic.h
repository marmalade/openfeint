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

#import "OFResource+Overridables.h"

@interface OFForumTopic : OFResource
{
	NSString* title;
	NSArray* children;
	NSInteger threadCount;
	BOOL isShowingChildren;
	NSInteger indentLevel;
	
	NSString* parentId;
}

+ (id)announcementsTopic;
+ (id)suggestionsTopic:(NSString*)topicId;

- (BOOL)hasParent;
- (BOOL)hasChildren;

@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSArray* children;
@property (nonatomic, assign) NSInteger threadCount;
@property (nonatomic, assign) BOOL isShowingChildren;
@property (nonatomic, assign) NSInteger indentLevel;

@end
