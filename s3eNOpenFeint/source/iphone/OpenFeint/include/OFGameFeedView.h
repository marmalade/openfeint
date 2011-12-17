//  Copyright 2009-2011 Aurora Feint, Inc.
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

#import "OFGameFeedSettings.h"

//////////////////////////////////////////////////////////////////////////////////////////
/// An instance of the OFGameFeedView implements a game feed view on screen.
/// 
/// The easiest way to use this feature is to create an OFGameFeedView and add it to your view, like so:
/// [myView addSubview:[OFGameFeedView gameFeedView]];
///
/// This will automatically place the feed at the bottom of the screen.
/// If you require more control over the behavior of the feed, or would like to customize
/// the look and feel, you may pass in a dictionary of settings to gameFeedViewWithSettings.
/// The settings are defined in OFGameFeedSettings.h
///
/// For example:
/// NSDictionary* settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
///                                  [NSNumber numberWithBool:YES], OFGameFeedSettingAnimateIn,
///                                  [NSNumber numberWithInt:OFGameFeedAlignment_TOP], OFGameFeedSettingAlignment,
///                                  nil];
/// [myView addSubview:[OFGameFeedView gameFeedViewWithSettings:settings]];
///
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFGameFeedView : UIView
{
}

//////////////////////////////////////////////////////////////////////////////////////////
/// Creates and returns a new OFGameFeedView.  The feed items will immediately be
/// requested from the server, and will start downloading.
//////////////////////////////////////////////////////////////////////////////////////////
+ (OFGameFeedView*)gameFeedView;
+ (OFGameFeedView*)gameFeedViewWithSettings:(NSDictionary*)settings;

//////////////////////////////////////////////////////////////////////////////////////////
/// Request a new set of game feed items from the server.  This is done automatically during
/// log in to OpenFeint, switching to a new account and the init of the game feed.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)refresh;

//////////////////////////////////////////////////////////////////////////////////////////
/// Helper method for animating the OFGameFeedView offscreen, then calling [removeFromSuperview]
//////////////////////////////////////////////////////////////////////////////////////////
-(void)animateOutAndRemoveFromSuperview;

//////////////////////////////////////////////////////////////////////////////////////////
/// In specific cases, you may need to explicitly rotate the game feed view to a different
/// orientation.  Games that rotate independent of the openGL view will need to
/// set this when rotation happens.
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@end
