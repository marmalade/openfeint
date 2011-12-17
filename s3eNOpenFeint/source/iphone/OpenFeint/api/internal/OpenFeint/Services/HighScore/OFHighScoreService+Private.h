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

#import "OFHighScoreService.h"
#import "OFHighScore.h"
#import "OFUser.h"
@class OFInvocation;
@class OFSqlQuery;

@interface OFHighScoreService (Private)

+ (void) setupOfflineSupport:(BOOL)recreateDB;
+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId;
+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText serverDate:(NSDate*)serverDate addToExisting:(BOOL) addToExisting;
+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL)addToExisting;
+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL)addToExisting shouldSubmit:(BOOL*)outShouldSubmit;
+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData blob:(NSData*)blob serverDate:(NSDate*)serverDate addToExisting:(BOOL)addToExisting shouldSubmit:(BOOL*)outShouldSubmit overrideExisting:(BOOL)overrideExisting;

+ (BOOL) synchHighScore:(NSString*)userId;
+ (void) getHighScoresLocal:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (NSArray*) getHighScoresLocal:(NSString*)leaderboardId;
+ (OFHighScore*)getHighScoreForUser:(OFUser*)userId leaderboardId:(NSString*)leaderboardId descendingSortOrder:(BOOL)descendingSortOrder;
// @return @c YES if a previous high score was retrieved, @c NO if there was no previous high score
+ (BOOL) getPreviousHighScoreLocal:(int64_t*)score forLeaderboard:(NSString*)leaderboardId;
+ (OFRequestHandle*) sendPendingHighScores:(NSString*)userId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;

+ (void) uploadBlob:(NSData*)blob forHighScore:(OFHighScore*)highScore;

+ (OFSqlQuery*) buildGetHighScoresQuery:(BOOL)descendingOrder limit:(int)limit;
+ (OFSqlQuery*) buildScoreToKeepQuery:(BOOL)descendingOrder;
+ (OFSqlQuery*) buildDeleteScoresQuery:(BOOL)descendingOrder;
+ (OFSqlQuery*) buildSetHighScoreQuery:(BOOL)replaceExisting;

// Hate this but it'd require a bit of a refactoring to get rid of due to batched high score submissions
+ (NSData*)getPendingBlobForLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score;
+ (void)setPendingBlob:(NSData*)blob forLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score;
+ (void)removePendingBlobForLeaderboard:(NSString*)leaderboardId;
+ (void)reportMissingBlobForHighScore:(OFHighScore*)highScore;

+ (OFRequestHandle*) submitHighScoreBatchArray:(NSArray*) scoreArray
                      withGameCenterDates:(NSDictionary*) dates message:(NSString*) message silently:(BOOL) silently 
                                     onSuccess:(OFInvocation*) success onFailure:(OFInvocation*) failure;

@end
