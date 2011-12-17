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
#import "OFOfflineService.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint.h"
#import "OFAchievement.h"
#import "OFUnlockedAchievement.h"
#import "OFAchievementService+Private.h"
#import "OFHighScore.h"
#import "OFHighScoreService+Private.h"
#import "OFLeaderboard+Sync.h"
#import "OFLeaderboardService.h"
#import "OFLeaderboardService+Private.h"
#import "OFLeaderboardAggregation.h"
#import "OFQueryStringWriter.h"
#import "OFUserService+Private.h"
#import "OpenFeint+Dashboard.h"
#import "OFResource.h"
#import "OFGameProfilePageInfo.h"
#import "OFBootstrap.h"
#import "OFUser.h"
#import "OpenFeint+UserOptions.h"
#import "OFSettings.h"
#import <sqlite3.h>
#import "OFResource+ObjC.h"
#import "OFSqlQuery.h"
#import "OFResource+ObjC.h"
#import "OFXmlElement.h"
#import "OFDependencies.h"

static NSString* formattedAppVersion;

@interface OFOfflineService (HiddenCPPStuff)
+ (void) shareKnownResourceMap:(NSMutableDictionary*)namedResourceMap;
@end


OPENFEINT_DEFINE_SERVICE_INSTANCE(OFOfflineService)

static OFSqlQuery* sSchemaVersionQuery;
static OFSqlQuery* sSetSchemaVersionQuery;

@implementation OFOfflineService

OPENFEINT_DEFINE_SERVICE(OFOfflineService)

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		OFPaginatedSeries* offlineResouces = nil;

		//Look for offline configuration file
		NSString* filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:"openfeint_offline_config"] ofType:@"xml"];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
		{
			int readInDate = [[NSUserDefaults standardUserDefaults] integerForKey:@"offline_config_file_date"];
			int lastModifiedDate = [[[[NSFileManager defaultManager]
                                      attributesOfItemAtPath:filePath error:NULL] fileModificationDate] 
                                    timeIntervalSince1970];
			
			if( readInDate != lastModifiedDate )
			{
				offlineResouces = [OFResource resourcesFromXml:[OFXmlElement elementWithData:[NSData dataWithContentsOfFile:filePath]] withMap:self.knownResources];
				
				for (id obj in offlineResouces)
				{
                    if ([obj isKindOfClass:[OFGameProfilePageInfo class]])
					{
						OFGameProfilePageInfo* profileInfo = (OFGameProfilePageInfo*)obj;
						[OpenFeint setLocalGameProfileInfo:profileInfo];
                        break;
					}
				}

                [[NSUserDefaults standardUserDefaults] setInteger:lastModifiedDate forKey:@"offline_config_file_date"];
                [[NSUserDefaults standardUserDefaults] synchronize];
			}
		}
		else
		{
            OFDeveloperWarning(@"OpenFeint 2.5 and greater requires an offline config.  You can download an offline config from your app page in the developer dashboard");
		}

        [OpenFeint setupOfflineDatabase];
        [OFOfflineService setupOfflineSupport];

        if(offlineResouces != nil)
        {
            for (id obj in offlineResouces)
            {
                if ([obj isKindOfClass:[OFOffline class]])
                {
                    OFOffline* offline = (OFOffline*)obj;
                    [OFLeaderboardService synchLeaderboardsList:offline.leaderboards aggregateLeaderboards:offline.leaderboardAggregations forUser:nil setSynchTime:NO];
                    [OFAchievementService synchAchievementsList:offline.achievements forUser:nil];
                }
            }
        }
	}

	return self;
}

- (void) dealloc
{
	if (formattedAppVersion)
		OFSafeRelease(formattedAppVersion);
	OFSafeRelease(sSchemaVersionQuery);
	OFSafeRelease(sSetSchemaVersionQuery);
	[OpenFeint teardownOfflineDatabase];
	[super dealloc];
}

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[OFOfflineService shareKnownResourceMap:namedResourceMap];
}

+ (void) shareKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFGameProfilePageInfo class] forKey:[OFGameProfilePageInfo getResourceName]];
	[namedResourceMap setObject:[OFOffline class] forKey:[OFOffline getResourceName]];
	[namedResourceMap setObject:[OFAchievement class] forKey:[OFAchievement getResourceName]];
	[namedResourceMap setObject:[OFUnlockedAchievement class] forKey:[OFUnlockedAchievement getResourceName]];
	[namedResourceMap setObject:[OFHighScore class] forKey:[OFHighScore getResourceName]];
	[namedResourceMap setObject:[OFLeaderboard_Sync class] forKey:[OFLeaderboard_Sync getResourceName]];
	[namedResourceMap setObject:[OFLeaderboardAggregation class] forKey:[OFLeaderboardAggregation getResourceName]];
	[namedResourceMap setObject:[OFUser class] forKey:[OFUser getResourceName]];
}

+ (void) setupOfflineSupport
{
	//[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"DROP TABLE IF EXISTS table_versions"] execute];
		
    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"CREATE TABLE IF NOT EXISTS table_versions("
		"name TEXT NOT NULL,"
 	    "version INTEGER NOT NULL,"
      "UNIQUE(name))"] execute];


	sSchemaVersionQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"SELECT * FROM table_versions "
                           "WHERE name = :name"];

	sSetSchemaVersionQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"REPLACE INTO table_versions "
		"(name, version) values "
                              "(:name, :version)" ];
	
	[OFOfflineService setTableVersion:@"table_versions" version:1];
	
	//This is needed because of the orginal online functionality
	//had an unlocked_achievements table
	OFSqlQuery* sUnlockAchievementsTableQuery;
	sUnlockAchievementsTableQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"INSERT INTO table_versions "
		"(name, version) values "
                                     "('unlocked_achievements', 1)"];
	[sUnlockAchievementsTableQuery execute];
	OFSafeRelease(sUnlockAchievementsTableQuery);
	
	BOOL recreateDB = NO; //ask about compile flag
	[OFAchievementService setupOfflineSupport:recreateDB];
	[OFHighScoreService setupOfflineSupport:recreateDB];
	[OFLeaderboardService setupOfflineSupport:recreateDB];
	[OFUserService setupOfflineSupport:recreateDB];
}

+ (void)migrateOfflineData
{
    // Invalid client application id
    if([OpenFeint clientApplicationId] == nil
       || [[OpenFeint clientApplicationId] isEqualToString:@"0"]
       || [[OpenFeint clientApplicationId] isEqualToString:@""])
    {
        return;
    }

    //keep the file in the original place until done
    NSString* dbFilename = [OFSettings documentsPathForFile:@"feint_offline"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:dbFilename])
    {
        return;
    }

    struct sqlite3* oldDatabaseHandle = NULL;
    if (SQLITE_OK != sqlite3_open([dbFilename UTF8String], &oldDatabaseHandle))
    {
        return;
    }

    // Migrate high score
    OFSqlQuery* scoreQuery = [[OFSqlQuery alloc] 
        initWithDb:oldDatabaseHandle 
        query:@"SELECT * FROM high_scores WHERE leaderboard_id = :leaderboardId AND server_sync_at IS NULL"];

    NSArray* leaderboards = [OFLeaderboardService getLeaderboardsLocal];
    for(OFLeaderboard* leaderboard in leaderboards)
    {
        [scoreQuery bind:@"leaderboardId" value:leaderboard.leaderboardId];
        for ([scoreQuery execute]; ![scoreQuery hasReachedEnd]; [scoreQuery step])
        {
            OFHighScore* score = [[OFHighScore alloc] initWithLocalSQL:scoreQuery forUser:nil rank:0];
            [OFHighScoreService
             localSetHighScore:score.score
             forLeaderboard:leaderboard.leaderboardId
             forUser:[scoreQuery stringValue:@"user_id"]
             displayText:score.displayText
             customData:score.customData
             blob:score.blob
             serverDate:nil
             addToExisting:NO
             shouldSubmit:NULL
             overrideExisting:YES];
            [score release];
        }
        [scoreQuery reset];
    }

    [scoreQuery release];

    // Migrate unlocked achievements
    OFSqlQuery* achievementQuery = [[OFSqlQuery alloc] 
        initWithDb:oldDatabaseHandle 
        query:@"SELECT * FROM unlocked_achievements WHERE achievement_definition_id = :definitionId AND server_sync_at IS NULL"];
        
    NSArray* achievements = [OFAchievementService getAchievementsLocal];
    for (OFAchievement* achievement in achievements)
    {
        [achievementQuery bind:@"definitionId" value:achievement.resourceId];
        for ([achievementQuery execute]; ![achievementQuery hasReachedEnd]; [achievementQuery step])
        {
            NSString* user = [achievementQuery stringValue:@"user_id"];
            double percent = [achievementQuery doubleValue:@"percent_complete"];
            [OFAchievementService localUpdateAchievement:achievement.resourceId forUser:user andPercentComplete:percent];
        }
        [achievementQuery reset];
    }

    [achievementQuery release];

    sqlite3_close(oldDatabaseHandle);

    //now we can safely move the original out of the way
    [OFSettings savePathForFile:@"feint_offline"];
    
}

+ (void) syncOfflineData:(OFOffline*)offline bootStrap:(OFBootstrap*)bootStrap;
{
	[OFUserService createLocalUser:bootStrap.user.resourceId userName:bootStrap.user.name profilePictureUrl:bootStrap.user.profilePictureUrl];
	[OFAchievementService synchAchievementsList:offline.achievements forUser:bootStrap.user.resourceId];
	[OFLeaderboardService synchLeaderboardsList:offline.leaderboards aggregateLeaderboards:offline.leaderboardAggregations forUser:bootStrap.user.resourceId setSynchTime:YES];

	BOOL isDbMigrated = [[NSUserDefaults standardUserDefaults] boolForKey: @"OFIsDdMigrated"];
	if (!isDbMigrated)
    {
        @try {
            [OFOfflineService migrateOfflineData];
            [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"OFIsDdMigrated"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        @catch (NSException *exception) {
            NSLog(@"Offline Migration Caught Exception %@ %@ %@", exception.name, exception.reason, exception.userInfo);
            NSString* message = [NSString stringWithFormat:@"Offline Migration Caught Exception %@ %@ %@", exception.name, exception.reason, exception.userInfo];
            [message writeToFile:[OFSettings savePathForFile:@"migration_error.txt"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
        }

    }
}

- (void) sendPendingData:(NSString*)userId
{
	[OFAchievementService sendPendingAchievements:userId syncOnly:YES onSuccessInvocation:nil onFailureInvocation:nil];
	[OFHighScoreService sendPendingHighScores:userId silently:YES onSuccessInvocation:nil onFailureInvocation:nil];
}

+ (void) getBootstrapCallParams:(OFQueryStringWriter*)params userId:(NSString*)userId
{
	[params ioNSStringToKey:@"achievements_sync_date" object:( [OFAchievementService getLastSyncDateForUserId:userId])];
	[params ioNSStringToKey:@"leaderboards_sync_date" object:( [OFLeaderboardService getLastSyncDateForUserId:userId])];
}

+ (int) getTableVersion:(NSString*) tableName
{
	int version = 0;
    [sSchemaVersionQuery bind:@"name" value:tableName];
    [sSchemaVersionQuery execute];
	if (sSchemaVersionQuery.lastStepResult == SQLITE_ROW) {
		version = [sSchemaVersionQuery intValue:@"version"];
	}
    [sSchemaVersionQuery reset];

	return version;
}

+ (BOOL) setTableVersion:(NSString*)tableName version:(int) version
{
	[sSetSchemaVersionQuery bind:@"name" value:tableName];
	[sSetSchemaVersionQuery bind:@"version" value:[NSString stringWithFormat:@"%d", version]];
	[sSetSchemaVersionQuery execute];
	BOOL success =  (sSetSchemaVersionQuery.lastStepResult == SQLITE_OK);
	[sSetSchemaVersionQuery reset];
	return success;
}

+ (NSString*) getFormattedAppVersion
{
	if (!formattedAppVersion) 
	{
		//format the client application version
		NSArray *parts = [[[OFSettings instance] clientBundleVersion] componentsSeparatedByString: @"."];
		int partCount = [parts count];
		int vMajor = (partCount > 0 ? [[parts objectAtIndex:0] integerValue]: 0);
		int vMinor = (partCount > 1 ? [[parts objectAtIndex:1] integerValue]: 0);
		int vPatch = (partCount > 2 ? [[parts objectAtIndex:2] integerValue]: 0);
		formattedAppVersion = [[NSString stringWithFormat:@"%04i.%02i.%02i", vMajor, vMinor, vPatch] retain];
	}
	
	return formattedAppVersion;
}
@end
