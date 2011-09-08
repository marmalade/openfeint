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

@class OFSelectUserController;
@class OFSelectUserWidget;
@class OFUser;
@class OFPaginatedSeries;

@protocol OFSelectUserWidgetDelegate
@required
- (void)selectUserWidget:(OFSelectUserWidget*)widget didSelectUser:(OFUser*)user;
@end

@interface OFSelectUserWidget : UIView
{
	OFSelectUserController* widgetController;
	id<OFSelectUserWidgetDelegate> delegate;
	BOOL hideHeader;
	BOOL disallowEdit;
}

@property (assign) id<OFSelectUserWidgetDelegate> delegate;
@property (assign) BOOL hideHeader;
@property (assign) BOOL disallowEdit;

- (void)reloadUserList;
- (void)setUserResources:(OFPaginatedSeries*)userResources;
- (void)setEditing:(BOOL)editing;

@end
