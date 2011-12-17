//  Copyright 2011 Aurora Feint, Inc.
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

#import "OpenFeint/OFHighScoreService.h"
#import "OFDelegate.h"
@interface OFHighScoreService (BackwardsCompatibility)
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex pageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserForLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getHighScoreNearCurrentUserForLeaderboard:(NSString*)leaderboardId andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) getLocalHighScores:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently deferred:(BOOL)deferred onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) setHighScore:(int64_t)score 
	  withDisplayText:(NSString*)displayText 
	   withCustomData:(NSString*)customData 
			 withBlob:(NSData*)blob
	   forLeaderboard:(NSString*)leaderboardId 
			 silently:(BOOL)silently 
             deferred:(BOOL)deferred
			onSuccess:(const OFDelegate&)onSuccess 
			onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage;
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage;
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage fromSynch:(BOOL)fromSynch;
+ (void) getAllHighScoresForLoggedInUser:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage;
+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId userMapMode:(NSString*)userMapMode onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) getDistributedHighScoresAtPage:(NSInteger)pageIndex 
										   pageSize:(NSInteger)pageSize 
										 scoreDelta:(NSInteger)scoreDelta
										 startScore:(NSInteger)startScore
									 forLeaderboard:(NSString*)leaderboardId 
										  onSuccess:(const OFDelegate&)onSuccess 
										  onFailure:(const OFDelegate&)onFailure;
+ (OFRequestHandle*) downloadBlobForHighScore:(OFHighScore*)highScore onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

@end
