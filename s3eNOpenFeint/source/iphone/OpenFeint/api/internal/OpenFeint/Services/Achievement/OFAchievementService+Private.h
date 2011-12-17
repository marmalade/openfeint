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

#import "OFAchievementService.h"
#import "OFAchievement.h"
#import "OFSqlQuery.h"

@interface OFAchievement ()
- (id)initWithLocalSQL:(OFSqlQuery*)queryRow;

@end


@interface OFAchievementService (Private)

+ (void) setupOfflineSupport:(BOOL)recreateDB;
+ (BOOL) localUpdateAchievement:(NSString*)achievementId forUser:(NSString*)userId andPercentComplete:(double)percentComplete;
+ (OFRequestHandle*) updateAchievements:(NSArray*)achievementIdList withPercentCompletes:(NSArray*)percentCompletes onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (double) getPercentComplete:(NSString*)achievementId forUser:(NSString*)userId;
+ (BOOL) synchUnlockedAchievement:(NSString*)achievementId forUser:(NSString*)userId gamerScore:(NSString*)gamerScore serverDate:(NSDate*)serverDate percentComplete:(double)percentComplete;
+ (void) synchAchievementsList:(NSArray*)achievements forUser:(NSString*)userId;
+ (NSString*) getLastSyncDateForUserId:(NSString*)userId;
+ (void) getAchievementsLocalInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
+ (NSArray*) getAchievementsLocal;
+ (BOOL) hasAchievements;
+ (OFRequestHandle*) sendPendingAchievements:(NSString*)userId syncOnly:(BOOL)syncOnly onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (OFAchievement*) getAchievement:(NSString*)achievementId;
+ (OFAchievement*) getAchievementLocalWithUnlockInfo:(NSString*)achievementId;

+(void)syncOfflineAchievements:(OFPaginatedSeries*)page;
+(void)finishAchievementsPage:(OFPaginatedSeries*)page duringSync:(BOOL)duringSync fromBatch:(BOOL) fromBatch;


@end
