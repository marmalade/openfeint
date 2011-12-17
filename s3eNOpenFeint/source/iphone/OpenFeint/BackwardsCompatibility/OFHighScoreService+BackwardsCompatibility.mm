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
#import "OFHighScoreService+BackwardsCompatibility.h"

@implementation OFHighScoreService (BackwardsCompatibility)
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPage:pageIndex 
          forLeaderboard:leaderboardId 
             friendsOnly: friendsOnly
     onSuccessInvocation:onSuccess.getInvocation() 
     onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPage:pageIndex 
          forLeaderboard:leaderboardId 
             friendsOnly:friendsOnly
                silently:silently
     onSuccessInvocation:onSuccess.getInvocation() 
     onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPage:pageIndex 
          forLeaderboard:leaderboardId 
        comparedToUserId:comparedToUserId
             friendsOnly:friendsOnly
                silently:silently
     onSuccessInvocation:onSuccess.getInvocation() 
     onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPage:pageIndex 
          forLeaderboard:leaderboardId 
        comparedToUserId:comparedToUserId
             friendsOnly:friendsOnly
                silently:silently
               timeScope:timeScope
     onSuccessInvocation:onSuccess.getInvocation() 
     onFailureInvocation:onFailure.getInvocation()];
    
}
+ (OFRequestHandle*) getPage:(NSInteger)pageIndex pageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently timeScope:(NSUInteger) timeScope onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPage:pageIndex 
                pageSize:pageSize
          forLeaderboard:leaderboardId 
        comparedToUserId:comparedToUserId
             friendsOnly:friendsOnly
                silently:silently
               timeScope:timeScope
     onSuccessInvocation:onSuccess.getInvocation() 
     onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPageWithLoggedInUserForLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPageWithLoggedInUserForLeaderboard:leaderboardId 
                                   onSuccessInvocation:onSuccess.getInvocation() 
                                   onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPageWithLoggedInUserWithPageSize:pageSize 
                                      forLeaderboard:leaderboardId 
                                 onSuccessInvocation:onSuccess.getInvocation() 
                                 onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [self getPageWithLoggedInUserWithPageSize:pageSize 
                                      forLeaderboard:leaderboardId 
                                            silently:silently
                                 onSuccessInvocation:onSuccess.getInvocation() 
                                 onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getHighScoreNearCurrentUserForLeaderboard:(NSString*)leaderboardId andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
{
    return [self getHighScoreNearCurrentUserForLeaderboard:leaderboardId
                                            andBetterCount:betterCount 
                                             andWorseCount:worseCount
                                 onSuccessInvocation:onSuccess.getInvocation() 
                                 onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getLocalHighScores:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getLocalHighScores:leaderboardId 
         onSuccessInvocation:onSuccess.getInvocation() 
         onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
        forLeaderboard:leaderboardId
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
        forLeaderboard:leaderboardId
              silently:silently
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
       withDisplayText:displayText
        forLeaderboard:leaderboardId
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
       withDisplayText:displayText
        forLeaderboard:leaderboardId
              silently:silently
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
       withDisplayText:displayText
        withCustomData:customData
        forLeaderboard:leaderboardId
              silently:silently
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently deferred:(BOOL)deferred onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
       withDisplayText:displayText
        withCustomData:customData
        forLeaderboard:leaderboardId
              silently:silently
              deferred:deferred
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (void) setHighScore:(int64_t)score 
	  withDisplayText:(NSString*)displayText 
	   withCustomData:(NSString*)customData 
			 withBlob:(NSData*)blob
	   forLeaderboard:(NSString*)leaderboardId 
			 silently:(BOOL)silently 
             deferred:(BOOL)deferred
			onSuccess:(const OFDelegate&)onSuccess 
			onFailure:(const OFDelegate&)onFailure
{
    [self setHighScore:score 
       withDisplayText:displayText
        withCustomData:customData
              withBlob:blob
        forLeaderboard:leaderboardId
              silently:silently
              deferred:deferred
   onSuccessInvocation:onSuccess.getInvocation() 
   onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
    return [self batchSetHighScores:highScoreBatchEntrySeries
                onSuccessInvocation:onSuccess.getInvocation() 
                onFailureInvocation:onFailure.getInvocation()
                    optionalMessage:submissionMessage];
}
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
    return [self batchSetHighScores:highScoreBatchEntrySeries
                           silently:silently
                onSuccessInvocation:onSuccess.getInvocation() 
                onFailureInvocation:onFailure.getInvocation()
                    optionalMessage:submissionMessage];
}
+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage fromSynch:(BOOL)fromSynch
{
    return [self batchSetHighScores:highScoreBatchEntrySeries
                           silently:silently
                onSuccessInvocation:onSuccess.getInvocation() 
                onFailureInvocation:onFailure.getInvocation()
                    optionalMessage:submissionMessage
                          fromSynch:fromSynch];
}
+ (void) getAllHighScoresForLoggedInUser:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
    [self getAllHighScoresForLoggedInUserInvocation:onSuccess.getInvocation() 
                                onFailureInvocation:onFailure.getInvocation()
                                    optionalMessage:submissionMessage];
}
+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getHighScoresFromLocation:origin radius:radius pageIndex:pageIndex forLeaderboard:leaderboardId
                onSuccessInvocation:onSuccess.getInvocation() 
                onFailureInvocation:onFailure.getInvocation()];
}
+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId userMapMode:(NSString*)userMapMode onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    [self getHighScoresFromLocation:origin radius:radius pageIndex:pageIndex forLeaderboard:leaderboardId
                        userMapMode:userMapMode
                onSuccessInvocation:onSuccess.getInvocation() 
                onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) getDistributedHighScoresAtPage:(NSInteger)pageIndex 
										   pageSize:(NSInteger)pageSize 
										 scoreDelta:(NSInteger)scoreDelta
										 startScore:(NSInteger)startScore
									 forLeaderboard:(NSString*)leaderboardId 
										  onSuccess:(const OFDelegate&)onSuccess 
										  onFailure:(const OFDelegate&)onFailure
{
    return [self getDistributedHighScoresAtPage:pageIndex pageSize:pageSize 
                                     scoreDelta:scoreDelta 
                                     startScore:startScore 
                                 forLeaderboard:leaderboardId 
                            onSuccessInvocation:onSuccess.getInvocation() 
                            onFailureInvocation:onFailure.getInvocation()];
}
+ (OFRequestHandle*) downloadBlobForHighScore:(OFHighScore*)highScore onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
 return [self downloadBlobForHighScore:highScore
                   onSuccessInvocation:onSuccess.getInvocation() 
                   onFailureInvocation:onFailure.getInvocation()];
}

@end
