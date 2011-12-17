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

#import <Foundation/Foundation.h>

@class OFAchievement;
@class OFHighScore;
@class OFLeaderboard;

//////////////////////////////////////////////////////////////////////////////////////////
/// Used by the OFBragDelegate to allow changing the prepopulatedText and suggested message
/// @param prepopulatedText     An NSString* for the uneditable text in the message
/// @param originalMessage      An NSString* that holds the default text which can be edited by the user
///                             if is left blank uses placeholder text of "Add a Message!".  The place holder text will not be sent along with the social notification.
///
/// @note                       These strings are not retained
//////////////////////////////////////////////////////////////////////////////////////////
typedef struct OFBragDelegateStrings
{
    NSString* prepopulatedText;
    NSString* originalMessage;
} OFBragDelegateStrings;

//////////////////////////////////////////////////////////////////////////////////////////
/// Adopt the OFBragDelegate Protocol to be able to modify our default text we have the 
/// player submit when wanting to brag about an achievement, leaderboard, ect..
//////////////////////////////////////////////////////////////////////////////////////////
@protocol OFBragDelegate
@optional

//////////////////////////////////////////////////////////////////////////////////////////
/// Override the text in the social notification when a user wants to brag about an achievment. 
///
/// @param achievement      The achievement the user would like to brag about.
/// @param overrideStrings	A OFBragDelegateStrings struct that holds the non-editable text and default message.  You can replace either of them in this structure
///
/// @note                   Return an unretained version of text and message, unless you want a reference. i.e. We don't release those NSString's for you
//////////////////////////////////////////////////////////////////////////////////////////
- (void)bragAboutAchievement:(OFAchievement*)achievement overrideStrings:(OFBragDelegateStrings*) overrideStrings;

//////////////////////////////////////////////////////////////////////////////////////////
/// Override the text in a social notification when a user wants to brag about all achievements unlocked in your game.
///
/// @param total		The total number of achievements in your game
/// @param unlocked		The number of achievements the user has unlocked.
/// @param overrideStrings	A OFBragDelegateStrings struct that holds the non-editable text and default message.  You can replace either of them in this structure
///
/// @note				Return an unretained version of text and message, unless you want a reference. i.e. We don't release those NSString's for you
//////////////////////////////////////////////////////////////////////////////////////////
- (void)bragAboutAllAchievementsWithTotal:(int)total unlockedAmount:(int)unlockedAmount overrideStrings:(OFBragDelegateStrings*) overrideStrings;

//////////////////////////////////////////////////////////////////////////////////////////
/// Override the text in a social notification when a user wants to brag about a high score.
///
/// @param highScore	The highscore the user wants to brag about
/// @param leaderboard	The leaderboard the high score belongs to.
/// @param overrideStrings	A OFBragDelegateStrings struct that holds the non-editable text and default message.  You can replace either of them in this structure
///
/// @note				Return an unretained version of text and message, unless you want a reference. i.e. We don't release those NSString's for you
//////////////////////////////////////////////////////////////////////////////////////////
- (void)bragAboutHighScore:(OFHighScore*)highScore onLeaderboard:(OFLeaderboard*)leaderboard overrideStrings:(OFBragDelegateStrings*) overrideStrings;
@end
