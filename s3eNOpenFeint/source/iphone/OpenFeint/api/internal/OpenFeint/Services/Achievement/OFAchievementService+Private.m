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
#import "OFAchievementService+Private.h"
#import "OFAchievement.h"
#import "OFSqlQuery.h"
#import "OFQueryStringWriter.h"
#import "OFActionRequestType.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import <sqlite3.h>
#import "OFPaginatedSeries.h"
#import "OFOfflineService.h"
#import "OFUser.h"
#import "OFGameCenterAchievement.h"
#import "OFUnlockedAchievement.h"
#import "OFNotification.h"
#import "OFSocialNotificationService+Private.h"
#import "OpenFeint+GameCenter.h"
#import "OFResource+ObjC.h"
#import "OFProvider.h"
#import "OFDependencies.h"

static OFSqlQuery* sUpdateQuery;
static OFSqlQuery* sPendingUnlocksQuery;
static OFSqlQuery* sDeleteRowQuery;
static OFSqlQuery* sAlreadyAtLeastPartlyCompleteQuery;
static OFSqlQuery* sServerSynchQuery;
static OFSqlQuery* sAchievementDefSynchQuery;
static OFSqlQuery* sLastSynchQuery;
static OFSqlQuery* sGetUnlockedAchievementsQuery;
static OFSqlQuery* sGetUnlockedAchievementQuery;
static OFSqlQuery* sGetAchievementsQuery;
static OFSqlQuery* sGetAchievementDefQuery;
static OFSqlQuery* sChangeNullUserQuery;
static OFSqlQuery* sSetUserSynchDateQuery;
static OFSqlQuery* sServerSynchQueryBootstrap;
static OFSqlQuery* sAchievementDefSynchQueryBootstrap;
static OFSqlQuery* sSetUserSynchDateQueryBootstrap;


@implementation OFAchievementService (Private)

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		//[OFAchievementService setupOfflineSupport];
	}
	
	return self;
}

- (void) dealloc
{
    OFSafeRelease(sUpdateQuery);
	OFSafeRelease(sPendingUnlocksQuery);
	OFSafeRelease(sDeleteRowQuery);
	OFSafeRelease(sAlreadyAtLeastPartlyCompleteQuery);
	OFSafeRelease(sServerSynchQuery);
	OFSafeRelease(sAchievementDefSynchQuery);
	OFSafeRelease(sLastSynchQuery);
	OFSafeRelease(sGetUnlockedAchievementsQuery);
	OFSafeRelease(sGetUnlockedAchievementQuery);
	OFSafeRelease(sGetAchievementsQuery);
	OFSafeRelease(sGetAchievementDefQuery);
	OFSafeRelease(sChangeNullUserQuery);
	OFSafeRelease(sServerSynchQueryBootstrap);
	OFSafeRelease(sAchievementDefSynchQueryBootstrap);
	OFSafeRelease(sSetUserSynchDateQueryBootstrap);
	[super dealloc];
}

+ (void) setupOfflineSupport:(BOOL)recreateDB
{
	BOOL oldSchema = NO;
	//Check for latest DB schema
	if( !recreateDB )
	{
		oldSchema = ([OFOfflineService getTableVersion:@"unlocked_achievements"] == 1);
	}
	
	if( recreateDB || oldSchema )
	{
		//Doesn't have new table schema, so create it.
		if( oldSchema )
		{
            [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"DROP TABLE IF EXISTS unlocked_achievements_save"] execute];
		    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE TABLE unlocked_achievements_save AS SELECT * FROM unlocked_achievements" doAssert:NO] executeWithAssert:NO];
		}
		
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"DROP TABLE IF EXISTS unlocked_achievements"] execute];
		
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"DROP TABLE IF EXISTS achievement_definitions"] execute];
	}
		
	[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE TABLE IF NOT EXISTS unlocked_achievements("
			   "user_id INTEGER NOT NULL,"
			   "achievement_definition_id INTEGER NOT NULL,"
			   "gamerscore INTEGER DEFAULT 0,"
			   "created_at INTEGER DEFAULT NULL,"
      "server_sync_at INTEGER DEFAULT NULL)"] execute];
	
	if([OFOfflineService getTableVersion:@"unlocked_achievements"] < 3)
	{
		//Percent complete achievements become supported in version 3 of the unlocked_achievements table
		//This ensures it only adds this column once for tables that are below this version (we change the version, a little below this to higher...)
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"ALTER TABLE unlocked_achievements "
          "ADD COLUMN percent_complete DOUBLE DEFAULT 100"] execute];
	}
	
	[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE UNIQUE INDEX IF NOT EXISTS unlocked_achievements_index "
      "ON unlocked_achievements (achievement_definition_id, user_id)"] execute];

	[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE TABLE IF NOT EXISTS unlocked_achievements_synch_date( "
               "user_id INTEGER NOT NULL,"
      "synch_date INTEGER NOT NULL)"] execute];
    
    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE UNIQUE INDEX IF NOT EXISTS unlocked_achievements_synch_date_index "
      "ON unlocked_achievements_synch_date (user_id)"] execute];
	
	[OFOfflineService setTableVersion:@"unlocked_achievements" version:3];
	
	int achievementDefinitionVersion = [OFOfflineService getTableVersion:@"achievement_definitions"];
	if( achievementDefinitionVersion == 0)
	{
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE TABLE IF NOT EXISTS achievement_definitions(" 
			   "id INTEGER NOT NULL,"
			   "title TEXT DEFAULT NULL,"
			   "description TEXT DEFAULT NULL,"
			   "gamerscore  INTEGER DEFAULT 0,"
			   "is_secret INTEGER DEFAULT 0,"
			   "icon_file_name TEXT DEFAULT NULL,"
			   "position INTEGER DEFAULT 0,"
			   "start_version  TEXT DEFAULT NULL,"
			   "end_version  TEXT DEFAULT NULL,"
          "server_sync_at INTEGER DEFAULT NULL)"] execute];
		
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"CREATE UNIQUE INDEX IF NOT EXISTS achievement_definitions_index "
          "ON achievement_definitions (id)"]execute];
	}
	else
	{
		if( achievementDefinitionVersion == 1)
		{
			[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"ALTER TABLE achievement_definitions " 
              "ADD COLUMN start_version  TEXT DEFAULT NULL"] execute];
		
			[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"ALTER TABLE achievement_definitions " 
              "ADD COLUMN end_version  TEXT DEFAULT NULL"] execute];
		}
		if( achievementDefinitionVersion != 3 )
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"ALTER TABLE achievement_definitions " 
          "ADD COLUMN position INT DEFAULT 0"] execute];
	}
	[OFOfflineService setTableVersion:@"achievement_definitions" version:3];
	
	
	if( oldSchema )
	{
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"INSERT INTO unlocked_achievements "
			"(user_id, achievement_definition_id,created_at) "
          "SELECT user_id, achievement_definition_id, strftime('%s', 'now') FROM unlocked_achievements_save" doAssert:NO] executeWithAssert:NO];
		
		[[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"DROP TABLE IF EXISTS unlocked_achievements_save"] execute];
	}

	//for testing
	//[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"UPDATE unlocked_achievements SET server_sync_at = NULL"] execute];

	//queries needed for offline achievement support
    sUpdateQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle]
                                            query:
                    @"REPLACE INTO unlocked_achievements "
		"(achievement_definition_id, user_id, percent_complete, created_at) "
                    "VALUES(:achievement_definition_id, :user_id, :percent_complete, strftime('%s', 'now'))"];
                    
	
	sPendingUnlocksQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
                            @"SELECT achievement_definition_id "
		"FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
                            "server_sync_at IS NULL"];
	
	sAlreadyAtLeastPartlyCompleteQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"SELECT percent_complete "
		"FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
                                          "achievement_definition_id = :achievement_definition_id"];
	
	sServerSynchQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"REPLACE INTO unlocked_achievements "
		"(user_id, achievement_definition_id, gamerscore, percent_complete, created_at, server_sync_at) "
                         "VALUES (:user_id, :achievement_definition_id, :gamerscore, :percent_complete, :server_sync_at, :server_sync_at)"];
	
	sServerSynchQueryBootstrap = [[OFSqlQuery alloc] initWithDb:[OpenFeint getBootstrapOfflineDatabaseHandle] query:
                         @"REPLACE INTO unlocked_achievements "
		 "(user_id, achievement_definition_id, gamerscore, percent_complete, created_at, server_sync_at) "
                         "VALUES (:user_id, :achievement_definition_id, :gamerscore, :percent_complete, :server_sync_at, :server_sync_at)"];

	sGetAchievementsQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
                             @"SELECT * FROM achievement_definitions ORDER BY position"];
		
	sGetAchievementDefQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
                               @"SELECT *, 0 AS unlocked_date FROM achievement_definitions WHERE id = :id"];
	
	sDeleteRowQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"DELETE FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
                       "achievement_definition_id = :achievement_definition_id"];
	
	sAchievementDefSynchQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"REPLACE INTO achievement_definitions "
		"(id, title, description, gamerscore, is_secret, icon_file_name, position, start_version, end_version, server_sync_at) "
                                 "VALUES (:id , :title , :description , :gamerscore , :is_secret , :icon_file_name, :position, :start_version, :end_version, strftime('%s', 'now'))"];
	
	sAchievementDefSynchQueryBootstrap = [[OFSqlQuery alloc] initWithDb:[OpenFeint getBootstrapOfflineDatabaseHandle] query:
                                 @"REPLACE INTO achievement_definitions "
		 "(id, title, description, gamerscore, is_secret, icon_file_name, position, start_version, end_version, server_sync_at) "
                                 "VALUES (:id , :title , :description , :gamerscore , :is_secret , :icon_file_name, :position, :start_version, :end_version, strftime('%s', 'now'))"];
	

    sLastSynchQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
        @"SELECT datetime(MAX(server_sync_at), 'unixepoch') as last_sync_date FROM "
        "(SELECT MIN(server_sync_at) AS server_sync_at FROM "
        "(SELECT MAX(server_sync_at) AS server_sync_at FROM "
        "(SELECT MAX(synch_date) AS server_sync_at FROM unlocked_achievements_synch_date WHERE user_id = :user_id UNION SELECT 0 AS server_sync_at) X "
                       "UNION SELECT MAX(server_sync_at) AS server_sync_at FROM achievement_definitions WHERE server_sync_at IS NOT NULL) Y ) Z"];
    
	sGetUnlockedAchievementsQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"select defs.*, unlocked_achievements.created_at AS unlocked_date "
		"FROM (select * from achievement_definitions WHERE start_version <= :app_version AND end_version >= :app_version) AS defs "
		"LEFT JOIN unlocked_achievements ON unlocked_achievements.achievement_definition_id = defs.id "
		"AND unlocked_achievements.user_id = :user_id "
                                     "ORDER BY unlocked_achievements.created_at DESC, position ASC, defs.id ASC"];
	
	sGetUnlockedAchievementQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"select defs.*, unlocked_achievements.created_at AS unlocked_date "
		"FROM (select * from achievement_definitions WHERE start_version <= :app_version AND end_version >= :app_version AND id = :achievement_id) AS defs "
		"LEFT JOIN unlocked_achievements ON unlocked_achievements.achievement_definition_id = defs.id "
		"AND unlocked_achievements.user_id = :user_id "
                                    "ORDER BY unlocked_achievements.created_at DESC, position ASC, defs.id ASC"];

	sChangeNullUserQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"UPDATE unlocked_achievements "
		"SET user_id = :user_id "
                            "WHERE user_id IS NULL or user_id = 0"];
    
    sSetUserSynchDateQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"REPLACE INTO unlocked_achievements_synch_date "
         "(user_id, synch_date) "
                              "VALUES (:user_id, strftime('%s', 'now'))"];
	
    sSetUserSynchDateQueryBootstrap = [[OFSqlQuery alloc] initWithDb:[OpenFeint getBootstrapOfflineDatabaseHandle] query:
                              @"REPLACE INTO unlocked_achievements_synch_date "
		  "(user_id, synch_date) "
                              "VALUES (:user_id, strftime('%s', 'now'))"];
}

+ (OFRequestHandle*) sendPendingAchievements:(NSString*)userId syncOnly:(BOOL)syncOnly onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFRequestHandle* handle = nil;

	//NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	if ([OpenFeint isOnline] && [userId longLongValue] > 0)
	{
		//One time case to sync up gamecenter witht he current OpenFeint User.
		if([OpenFeint isLoggedIntoGameCenter] && ![OpenFeint isSynchedWithGameCenterAchievements])
		{
			//Sync everything to game center everytime since we don't have a sync date with game center stored on its server (we can't assume it is the same sync date as above because of new games moving to this integration).
			NSArray* allAchievements = [OFAchievementService getAchievementsLocal];
			NSMutableArray* allAchievementIds = [[NSMutableArray new] autorelease];
			NSMutableArray* allPercentCompletes = [[NSMutableArray new] autorelease];
			for(uint i = 0; i < [allAchievements count]; i++)
			{
				OFAchievement* achievement = [allAchievements objectAtIndex:i];
				[allAchievementIds addObject:achievement.resourceId];
				[allPercentCompletes addObject:[NSNumber numberWithDouble:achievement.percentComplete]];
			}
			
			if([allAchievementIds count] > 0 && [allPercentCompletes count] > 0)
			{
				OFGameCenterAchievement* gcAchievement = [[OFGameCenterAchievement new] autorelease];
				gcAchievement.achievementIds = allAchievementIds;
				gcAchievement.percentsComplete = allPercentCompletes;
				gcAchievement.batch = YES;
				gcAchievement.sync = syncOnly;
				handle = [gcAchievement submitOnSuccessInvocation:success onFailureInvocation:failure];
			}
			[OpenFeint setSynchWithGameCenterAchievements:YES];
		}
		else
		{
			//associate any offline achievements to user
			[sChangeNullUserQuery bind:@"user_id" value:userId];
			[sChangeNullUserQuery execute];
			[sChangeNullUserQuery reset];
			
			NSMutableArray* achievementIdList = [[NSMutableArray new] autorelease];
			NSMutableArray* percentCompleteList = [[NSMutableArray new] autorelease];
			
			[sPendingUnlocksQuery bind:@"user_id" value:userId];
			for ([sPendingUnlocksQuery execute]; !sPendingUnlocksQuery.hasReachedEnd; [sPendingUnlocksQuery step])
			{
				NSString* achievementId = [NSString stringWithFormat:@"%d", [sPendingUnlocksQuery intValue:@"achievement_definition_id"]];
				[achievementIdList addObject:achievementId];
				
				[sAlreadyAtLeastPartlyCompleteQuery bind:@"achievement_definition_id" value:achievementId];
				[sAlreadyAtLeastPartlyCompleteQuery bind:@"user_id" value:userId];		
				[sAlreadyAtLeastPartlyCompleteQuery execute];
				float percentComplete = (double)([sAlreadyAtLeastPartlyCompleteQuery doubleValue:@"percent_complete"]);
				[sAlreadyAtLeastPartlyCompleteQuery reset];
				
				[percentCompleteList addObject:[NSNumber numberWithDouble:percentComplete]];
			}
			[sPendingUnlocksQuery reset];
			
			if ([achievementIdList count] > 0 && [percentCompleteList count] > 0)
			{
				OFGameCenterAchievement* gcAchievement = [[OFGameCenterAchievement new] autorelease];
				gcAchievement.achievementIds = achievementIdList;
				gcAchievement.percentsComplete = percentCompleteList;
				gcAchievement.batch = YES;
				gcAchievement.sync = syncOnly;
				handle = [gcAchievement submitOnSuccessInvocation:success onFailureInvocation:failure];
			}
			
		}
	}
	
	return handle;
}

+ (BOOL)localUpdateAchievement:(NSString*)achievementId forUser:(NSString*)userId andPercentComplete:(double)percentComplete
{
    if ([achievementId length] == 0)
        return NO;
    
    if (percentComplete <= [OFAchievementService getPercentComplete:achievementId forUser:userId])
        return NO;

	[sGetAchievementDefQuery bind:@"id" value:achievementId];
	[sGetAchievementDefQuery execute];
	int gamerscore = [sGetAchievementDefQuery intValue:@"gamerscore"];

	double currentPercentComplete = [self getPercentComplete:achievementId forUser:userId];
	
	if (gamerscore > 0 && percentComplete == 100.0 && currentPercentComplete != 100.0)
	{
		OFUser* localUser = [OpenFeint localUser];
		[localUser adjustGamerscore:gamerscore];
		[OpenFeint setLocalUser:localUser];
	}

	[sGetAchievementDefQuery reset];

    [sUpdateQuery bind:@"achievement_definition_id" value:achievementId];
    [sUpdateQuery bind:@"user_id"  value:userId];
    [sUpdateQuery bind:@"percent_complete" value:[NSString stringWithFormat:@"%lf", percentComplete]];
    [sUpdateQuery execute];
	BOOL success = (sUpdateQuery.lastStepResult == SQLITE_OK);
	[sUpdateQuery reset];
	
	return success;
}

+ (NSString*) getLastSyncDateForUserId:(NSString*)userId
{
	NSString* lastSyncDate = NULL;
	[sLastSynchQuery bind:@"user_id" value:userId];
	[sLastSynchQuery execute];
	lastSyncDate = [sLastSynchQuery stringValue:@"last_sync_date"];
	[sLastSynchQuery reset];
	return lastSyncDate;
}

+ (OFRequestHandle*) updateAchievements:(NSArray*)achievementIdList withPercentCompletes:(NSArray*)percentCompletes onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	{
        [params pushScope:@"achievement_list" isArray:YES];
		
		BOOL anyValidAchievements = NO;
		for (uint i = 0; i < [achievementIdList count] && i < [percentCompletes count]; i++)
		{
			NSString* achievementId = [achievementIdList objectAtIndex:i];
			
			//No Blank achievement id submissions
			if(achievementId && ![achievementId isEqualToString:@""])
			{
				anyValidAchievements = YES;
				double percentComplete = [(NSNumber*)[percentCompletes objectAtIndex:i] doubleValue];
				
                [params pushScope:@"achievement" isArray:NO];
				[params ioNSStringToKey:@"achievement_definition_id" object:achievementId];
				[params ioDoubleToKey:@"percent_complete" value:percentComplete];
                [params popScope];
			}
		}
		
		if(!anyValidAchievements)
		{
			//TODO Change To Assert when asserts pop alert views
			//No valid achievement ids
            [failure invoke];
			return nil;
		}
        [params popScope];
	}
	
	return [[self sharedInstance] 
	 postAction:@"users/@me/unlocked_achievements.xml"
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:success
	 withFailureInvocation:failure
	 withRequestType:OFActionRequestSilent
	 withNotice:[OFNotificationData dataWithText:@"Submitted Unlocked Achivements" andCategory:kNotificationCategoryAchievement andType:kNotificationTypeSubmitting]];
}

// Note: this should be moved into public API
+ (double) getPercentComplete:(NSString*)achievementId forUser:(NSString*)userId
{
	[sAlreadyAtLeastPartlyCompleteQuery bind:@"achievement_definition_id" value:achievementId];
	[sAlreadyAtLeastPartlyCompleteQuery bind:@"user_id" value:userId];		
	[sAlreadyAtLeastPartlyCompleteQuery execute];
	float percentComplete = (double)([sAlreadyAtLeastPartlyCompleteQuery doubleValue:@"percent_complete"]);
	[sAlreadyAtLeastPartlyCompleteQuery reset];
	return percentComplete;
}

+ (BOOL) synchUnlockedAchievement:(NSString*)achievementId forUser:(NSString*)userId gamerScore:(NSString*)gamerScore serverDate:(NSDate*)serverDate percentComplete:(double)percentComplete
{
	OFSqlQuery* serverSynchQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		serverSynchQuery = sServerSynchQueryBootstrap;
	}
	else 
	{
		serverSynchQuery = sServerSynchQuery;

	}
	
	NSString* serverSynch = [NSString stringWithFormat:@"%d", (long)[serverDate timeIntervalSince1970]];
	[serverSynchQuery bind:@"achievement_definition_id" value:achievementId];
	[serverSynchQuery bind:@"user_id" value:userId];
	[serverSynchQuery bind:@"gamerscore" value:gamerScore];
	[serverSynchQuery bind:@"server_sync_at" value:serverSynch];
	[serverSynchQuery bind:@"percent_complete" value:[NSString stringWithFormat:@"%lf", percentComplete]];
	[serverSynchQuery execute];
	BOOL success = (serverSynchQuery.lastStepResult == SQLITE_OK);
	[serverSynchQuery reset];
	return success;
}

+ (void)synchAchievementsList:(NSArray*)achievements forUser:(NSString*)userId
{
	struct sqlite3* databaseHandle = nil;
	OFSqlQuery* achievementDefSynchQuery = nil;
	OFSqlQuery* setUserSynchDataQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		achievementDefSynchQuery = sAchievementDefSynchQueryBootstrap;
		setUserSynchDataQuery = sSetUserSynchDateQueryBootstrap;
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		achievementDefSynchQuery = sAchievementDefSynchQuery;
		setUserSynchDataQuery = sSetUserSynchDateQuery;
	}

	unsigned int achievementCnt = [achievements count];
	[[OFSqlQuery queryWithDb:databaseHandle query:@"BEGIN TRANSACTION"] execute];
	for (unsigned int i = 0; i < achievementCnt; i++)
	{
		OFAchievement* achievement = [achievements objectAtIndex:i];
		
		//update or add achievement definition as needed
		 [achievementDefSynchQuery bind:@"id" value:achievement.resourceId];
		 [achievementDefSynchQuery bind:@"title" value:achievement.title];
		 [achievementDefSynchQuery bind:@"description" value:achievement.description];
         [achievementDefSynchQuery bind:@"gamerscore" value:[NSString stringWithFormat:@"%d", achievement.gamerscore]];
		 [achievementDefSynchQuery bind:@"is_secret" value:[NSString stringWithFormat:@"%d", (achievement.isSecret? 1 : 0)]];
		 [achievementDefSynchQuery bind:@"position" value:[NSString stringWithFormat:@"%d", achievement.position]];
		 [achievementDefSynchQuery bind:@"icon_file_name" value:achievement.iconUrl];
		 [achievementDefSynchQuery bind:@"start_version" value:achievement.startVersion];
		 [achievementDefSynchQuery bind:@"end_version" value:achievement.endVersion];
		 [achievementDefSynchQuery execute];
		 [achievementDefSynchQuery reset];

		//add user achievements as need 
		if (achievement.percentComplete > 0.0) 
		{
			[OFAchievementService 
			 synchUnlockedAchievement:achievement.resourceId
			 forUser:userId
			 gamerScore:[NSString stringWithFormat:@"%d", achievement.gamerscore]
			 serverDate:achievement.unlockDate
			 percentComplete:achievement.percentComplete];
		}
	}
	[[OFSqlQuery queryWithDb:databaseHandle query:@"COMMIT"] execute];
    [setUserSynchDataQuery bind:@"user_id" value:userId];
    [setUserSynchDataQuery execute];
    [setUserSynchDataQuery reset];
}

+ (void) getAchievementsLocalInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure 
{
	NSArray* achievements = [self getAchievementsLocal];
	[onSuccess invokeWith:[OFPaginatedSeries paginatedSeriesFromArray:achievements]];
}


+ (NSArray*) getAchievementsLocal
{
	NSMutableArray* achievements = [NSMutableArray arrayWithCapacity:20];
	
	[sGetUnlockedAchievementsQuery bind:@"app_version" value:[OFOfflineService getFormattedAppVersion]];
	[sGetUnlockedAchievementsQuery bind:@"user_id" value:[OpenFeint lastLoggedInUserId]];
	for ([sGetUnlockedAchievementsQuery execute]; !sGetUnlockedAchievementsQuery.hasReachedEnd; [sGetUnlockedAchievementsQuery step])
	{
		[achievements addObject:[[[OFAchievement alloc] initWithLocalSQL:sGetUnlockedAchievementsQuery] autorelease]];
	}
	
	[sGetUnlockedAchievementsQuery reset];
	
	return achievements;
}

+ (BOOL) hasAchievements
{
	[sGetAchievementsQuery execute]; 
	BOOL hasActive = (sGetAchievementsQuery.lastStepResult == SQLITE_ROW);
	[sGetAchievementsQuery reset];
	return hasActive;
}

+ (OFAchievement*) getAchievement:(NSString*)achievementId
{
	[sGetAchievementDefQuery bind:@"id" value:achievementId];
	OFAchievement* achievement = nil;
	[sGetAchievementDefQuery execute];
	if (sGetAchievementDefQuery.lastStepResult == SQLITE_ROW)
	{
		achievement = [[[OFAchievement alloc] initWithLocalSQL:sGetAchievementDefQuery] autorelease];
	}
	[sGetAchievementDefQuery reset];
	return achievement;
}

+ (OFAchievement*) getAchievementLocalWithUnlockInfo:(NSString*)achievementId
{
	OFAchievement* achievement = nil;
	[sGetUnlockedAchievementQuery bind:@"app_version" value:[OFOfflineService getFormattedAppVersion]];
	[sGetUnlockedAchievementQuery bind:@"user_id" value:[OpenFeint lastLoggedInUserId]];
	[sGetUnlockedAchievementQuery bind:@"achievement_id" value:achievementId];
	[sGetUnlockedAchievementQuery execute];
	if (sGetUnlockedAchievementQuery.lastStepResult == SQLITE_ROW)
	{
		achievement = [[[OFAchievement alloc] initWithLocalSQL:sGetUnlockedAchievementQuery] autorelease];
	}
	
	[sGetUnlockedAchievementQuery reset];
	return achievement;
}

//piece pulled out so the GameCenter integration can call it
+(void)syncOfflineAchievements:(OFPaginatedSeries*)page {
	unsigned int achievementCnt = [page count];
	NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	OFUnlockedAchievement* unlockedAchievement = nil;
	
	for (unsigned int i = 0; i < achievementCnt; i++)
	{
		unlockedAchievement = [page objectAtIndex:i];
		if (!unlockedAchievement.isInvalidResult)
		{
			NSDate* unlockedDate = unlockedAchievement.achievement.unlockDate;
			if (!unlockedDate)
			{
				unlockedDate = [NSDate date];
			}
			[OFAchievementService 
			 synchUnlockedAchievement:unlockedAchievement.achievement.resourceId
			 forUser:lastLoggedInUser
			 gamerScore:[NSString stringWithFormat:@"%d", unlockedAchievement.achievement.gamerscore]
			 serverDate:unlockedDate
			 percentComplete:unlockedAchievement.percentComplete];		
		}
	}
}

+(void)finishAchievementsPage:(OFPaginatedSeries*)page duringSync:(BOOL)duringSync fromBatch:(BOOL) fromBatch 
{
	unsigned int achievementCnt = [page count];
	
	if (achievementCnt > 1)
	{
		if (!duringSync)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:@"Submitted Achievements To Server" andCategory:kNotificationCategoryAchievement andType:kNotificationTypeSuccess];
			[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
		}
	}
	
    
}


@end
