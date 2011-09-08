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

#import "OFDependencies.h"
#import "OpenFeint.h"
#import "OFHttpNestedQueryStringWriter.h"

@interface OpenFeint (UserStats)

//- (void) _incrementSessionTime;
+ (void)intiailizeUserStats;
+ (void)resetUserStats;
+ (void)shutdownUserStats;

+ (void)setNumberOfGameSessions:(NSInteger)value;
+ (void)incrementNumberOfGameSessions;
+ (NSInteger)numberOfGameSessions;

+ (void)setTotalGameSessionsDuration:(NSInteger)value;
+ (void)incrementTotalGameSessionsDurationBy:(NSInteger)value;
+ (NSInteger)totalGameSessionsDuration;

+ (void)setNumberOfDashboardLaunches:(NSInteger)value;
+ (void)incrementNumberOfDashboardLaunches;
+ (NSInteger)numberOfDashboardLaunches;

+ (void)setTotalDashboardDuration:(NSInteger)value;
+ (void)incrementTotalDashboardDurationBy:(NSInteger)value;
+ (NSInteger)totalDashboardDuration;

+ (void)setNumberOfOnlineGameSessions:(NSInteger)value;
+ (void)incrementNumberOfOnlineGameSessions;
+ (NSInteger)numberOfOnlineGameSessions;

+ (void)dashboardLaunched;
+ (void)dashboardClosed;
+ (void)saveSessionDuration;
+ (void)sessionNotActive;
+ (void)sessionActive;

+ (void) getUserStatsParams:(OFHttpNestedQueryStringWriter*)params;
+ (NSString*)statUserKeyName:(NSString*)key;
+ (void) setUserStatValue:(NSString*)key value:(NSInteger)value;
+ (NSInteger) getUserStatValue:(NSString*)key;

@end
