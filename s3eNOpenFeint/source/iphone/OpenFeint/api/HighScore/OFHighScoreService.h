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

#import "OFService.h"
#import "OFHighScoreBatchEntry.h"
#import <CoreLocation/CoreLocation.h>
#import "OFInvocation.h"

@class OFLeaderboard;
@class OFHighScore;
@class OFRequestHandle;

static const uint HIGH_SCORE_PAGE_SIZE = 25;

@interface OFHighScoreService : OFService
{
	NSMutableArray* mPendingBlobs;
	NSMutableArray* mPendingScores;
}

OPENFEINT_DECLARE_AS_SERVICE(OFHighScoreService);

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex pageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserForLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (OFRequestHandle*) getHighScoreNearCurrentUserForLeaderboard:(NSString*)leaderboardId andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (void) getLocalHighScores:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

// When withDisplayText is set it's shown INSTEAD of the score. If you want to show the score as well 
// as something else the score must be embedded in the display text
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

// When withCustomData is stored on the server along with the score
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently deferred:(BOOL)deferred onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;


// The blob can be up to 50k and must be downloaded separately 
+ (void) setHighScore:(int64_t)score 
	  withDisplayText:(NSString*)displayText 
	   withCustomData:(NSString*)customData 
			 withBlob:(NSData*)blob
	   forLeaderboard:(NSString*)leaderboardId 
			 silently:(BOOL)silently 
             deferred:(BOOL)deferred
  onSuccessInvocation:(OFInvocation*)onSuccess 
  onFailureInvocation:(OFInvocation*)onFailure;

+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage;
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage;
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage fromSynch:(BOOL)fromSynch;

// High scores returned through getAllHighScoresForLoggedInUser do not have their rank set.
+ (void) getAllHighScoresForLoggedInUserInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure optionalMessage:(NSString*)submissionMessage;

+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId userMapMode:(NSString*)userMapMode onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;

+ (OFRequestHandle*) getDistributedHighScoresAtPage:(NSInteger)pageIndex 
										   pageSize:(NSInteger)pageSize 
										 scoreDelta:(NSInteger)scoreDelta
										 startScore:(NSInteger)startScore
									 forLeaderboard:(NSString*)leaderboardId 
                                onSuccessInvocation:(OFInvocation*)onSuccess 
                                onFailureInvocation:(OFInvocation*)onFailure;

+ (OFRequestHandle*) downloadBlobForHighScore:(OFHighScore*)highScore onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
@end
