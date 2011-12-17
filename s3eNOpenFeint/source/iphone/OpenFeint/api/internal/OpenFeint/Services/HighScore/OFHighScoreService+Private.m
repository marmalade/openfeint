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

#import "OFHighScoreService+Private.h"
#import "OFSqlQuery.h"
#import "OFActionRequestType.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import <sqlite3.h>
#import "OFLeaderboardService+Private.h"
#import "OFHighScore.h"
#import "OFUser.h"
#import "OFUserService+Private.h"
#import "OFPaginatedSeries.h"
#import "OFOfflineService.h"
#import "OFLeaderboard+Sync.h"
#import "OFNotification.h"
#import "OFCloudStorageService.h"
#import "OFS3Response.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+GameCenter.h"
#import "OFQueryStringWriter.h"
#import "OFHighScoreBatchEntry.h"
#import "OFResource+ObjC.h"
#import "OFInvocation.h"
#import "OFProvider.h"
#import "OFDependencies.h"

@interface OFHighScore ()
- (id)initWithLocalSQL:(OFSqlQuery*)queryRow forUser:(OFUser*)hsUser rank:(NSUInteger)scoreRank;
@end

static OFSqlQuery* sPendingHighScoresQuery;
static OFSqlQuery* sServerSynchQuery;
static OFSqlQuery* sMakeOnlyOneSynchQuery;
static OFSqlQuery* sLastSynchQuery;
static OFSqlQuery* sChangeNullUserQuery;
static OFSqlQuery* sNullUserLeaderboardsQuery;
static OFSqlQuery* sMakeOnlyOneSynchQueryBootstrap;

// A regular dictionary won't work. If you submit 2 scores in quick succession then it's important that when the first call returns it doesn't think
// the second calls blob belongs to it. We also want to clear based on only leaderboard id so using a combination of leaderboard and score as a NSDictionaty key wont work.
@interface OFPendingBlob : NSObject
{
	NSString* leaderboardId;
	int64_t score;
	NSData* blob;
}

@property (nonatomic, retain) NSString* leaderboardId;
@property (nonatomic, retain) NSData* blob;
@property (nonatomic, assign) int64_t score;

@end

@implementation OFPendingBlob

@synthesize leaderboardId, score, blob;

- (id)initWithLeaderboardId:(NSString*)_leaderboardId andScore:(int64_t)_score andBlob:(NSData*)_blob
{
	self = [super init];
	if (self)
	{
		self.leaderboardId = _leaderboardId;
		self.score = _score;
		self.blob = _blob;
	}
	return self;
}

- (void)dealloc
{
	self.leaderboardId = nil;
	self.blob = nil;
	[super dealloc];
}

@end


@implementation OFHighScoreService (Private)

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		mPendingBlobs = [NSMutableArray new];
		mPendingScores = [NSMutableArray new];
	}
	
	return self;
}

- (void) dealloc
{
	OFSafeRelease(mPendingBlobs);
    OFSafeRelease(mPendingScores);
	OFSafeRelease(sPendingHighScoresQuery);
	OFSafeRelease(sServerSynchQuery);
	OFSafeRelease(sMakeOnlyOneSynchQuery);
	OFSafeRelease(sLastSynchQuery);
	OFSafeRelease(sChangeNullUserQuery);
	OFSafeRelease(sNullUserLeaderboardsQuery);
	OFSafeRelease(sMakeOnlyOneSynchQueryBootstrap);
	[super dealloc];
}

+ (void) setupOfflineSupport:(BOOL)recreateDB
{
	if( recreateDB )
	{
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"DROP TABLE IF EXISTS high_scores"] execute];
	}
	
	//Special PG patch
    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
     @"ALTER TABLE high_scores " 
      "ADD COLUMN display_text TEXT DEFAULT NULL" doAssert:NO] executeWithAssert:NO];

	int highScoresVersion = [OFOfflineService getTableVersion:@"high_scores"];
	if (highScoresVersion == 1)
	{
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"ALTER TABLE high_scores " 
          "ADD COLUMN custom_data TEXT DEFAULT NULL"]execute];
		highScoresVersion = 2;
	}
	if (highScoresVersion == 2)
	{
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"ALTER TABLE high_scores " 
          "ADD COLUMN blob BLOB DEFAULT NULL"] execute];
	}
	else
	{
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"CREATE TABLE IF NOT EXISTS high_scores("
			"user_id INTEGER NOT NULL,"
			"leaderboard_id INTEGER NOT NULL,"
			"score INTEGER DEFAULT 0,"
			"display_text TEXT DEFAULT NULL,"
			"custom_data TEXT DEFAULT NULL,"
			"server_sync_at INTEGER DEFAULT NULL,"
			"blob BLOB DEFAULT NULL,"
          "UNIQUE(leaderboard_id, user_id, score))"] execute];
		
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
         @"CREATE INDEX IF NOT EXISTS high_scores_index "
          "ON high_scores (user_id, leaderboard_id)"] execute];
	}
	[OFOfflineService setTableVersion:@"high_scores" version:3];
	
	
	sPendingHighScoresQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"SELECT leaderboard_id, score, display_text, custom_data, blob "
		"FROM high_scores "
		"WHERE user_id = :user_id AND "
                               "server_sync_at IS NULL"];
	
	//for testing
	//[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:@"UPDATE high_scores SET server_sync_at = NULL"] execute];
	
	sMakeOnlyOneSynchQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"UPDATE high_scores "
		"SET server_sync_at = :server_sync_at "
		"WHERE user_id = :user_id AND "
		"leaderboard_id = :leaderboard_id AND "
		"score != :score AND "
        "server_sync_at IS NULL"];
	
	sMakeOnlyOneSynchQueryBootstrap = [[OFSqlQuery alloc] initWithDb:[OpenFeint getBootstrapOfflineDatabaseHandle] query:
		@"UPDATE high_scores "
	  "SET server_sync_at = :server_sync_at "
	  "WHERE user_id = :user_id AND "
	  "leaderboard_id = :leaderboard_id AND "
	  "score != :score AND "
        "server_sync_at IS NULL"];
	
	sChangeNullUserQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"UPDATE high_scores "
		"SET user_id = :user_id "
        "WHERE user_id IS NULL or user_id = 0"];
	
	sNullUserLeaderboardsQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
		@"SELECT DISTINCT(leaderboard_id) FROM high_scores "
        "WHERE user_id IS NULL or user_id = 0"];
}

+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:nil serverDate:nil addToExisting:NO];
}

+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText serverDate:(NSDate*)serverDate addToExisting:(BOOL) addToExisting
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:nil serverDate:nil addToExisting:NO];
}

+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL) addToExisting
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:customData serverDate:serverDate addToExisting:addToExisting shouldSubmit:nil];
}

+ (BOOL) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL)addToExisting shouldSubmit:(BOOL*)outShouldSubmit
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:customData blob:nil serverDate:serverDate addToExisting:addToExisting shouldSubmit:nil overrideExisting:YES];
}

+ (BOOL) localSetHighScore:(int64_t)score 
			forLeaderboard:(NSString*)leaderboardId 
				   forUser:(NSString*)userId 
			   displayText:(NSString*)displayText 
				customData:(NSString*)customData 
					  blob:(NSData*)blob
				serverDate:(NSDate*)serverDate 
			 addToExisting:(BOOL) addToExisting 
			  shouldSubmit:(BOOL*)outShouldSubmit
		  overrideExisting:(BOOL)overrideExisting
{
	OFSqlQuery* makeOnlyOneSynchQuery= nil;
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		makeOnlyOneSynchQuery = sMakeOnlyOneSynchQueryBootstrap;
	}
	else 
	{
		makeOnlyOneSynchQuery = sMakeOnlyOneSynchQuery;
	}
	
	BOOL success = NO;
	BOOL shouldSubmitToServer = YES;
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
    

	if (leaderboard && (!leaderboard.isAggregate || addToExisting))
	{
		NSString* serverSynch = nil;
		if( serverDate )
		{
			serverSynch = [NSString stringWithFormat:@"%d", (long)[serverDate timeIntervalSince1970]];
		}
		NSString*lastSyncDate = [OFLeaderboardService getLastSyncDateUnixForUserId:userId];
		int64_t previousScore = 0;
		BOOL hasPreviousScore = [OFHighScoreService getPreviousHighScoreLocal:&previousScore forLeaderboard:leaderboardId];
		if (addToExisting && hasPreviousScore)
		{
			score =  previousScore + score;
		}
		
		//@note allowPostingLowerScores actually means allow posting WORSE scores
		if (!leaderboard.allowPostingLowerScores && hasPreviousScore)
		{
			if ((leaderboard.descendingSortOrder && score <= previousScore) ||	// if higher is better and this new score is lower
				(!leaderboard.descendingSortOrder && score >= previousScore))	// or lower is better and this new score is higher
			{
				if (blob == nil || score != previousScore)
				{
					shouldSubmitToServer = NO;										// don't submit it to the server
				}
			}
		}
		
		
		OFSqlQuery* setHighScoreQuery = [OFHighScoreService buildSetHighScoreQuery:overrideExisting];
		
		NSString* sScore = [NSString stringWithFormat:@"%qi", score];
		[setHighScoreQuery bind:@"user_id" value:userId];		
		[setHighScoreQuery bind:@"leaderboard_id" value:leaderboardId];
		[setHighScoreQuery bind:@"score" value:sScore];
		[setHighScoreQuery bind:@"display_text" value:displayText];
		[setHighScoreQuery bind:@"custom_data" value:customData];
		NSString* newScoresSynchTime = serverSynch;
		if (!newScoresSynchTime && !shouldSubmitToServer)
		{
			// If it shouldn't be submitted then mark it as synched right away
			newScoresSynchTime = [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]];
		}
		[setHighScoreQuery bind:@"server_sync_at" value:newScoresSynchTime];
		if (blob)
		{
			[setHighScoreQuery bind:@"blob" value:blob.bytes size:blob.length];
		}
		
		[setHighScoreQuery execute];
		success = (setHighScoreQuery.lastStepResult == SQLITE_OK);
		[setHighScoreQuery reset];
		
		
		OFSqlQuery* scoreToKeepQuery = [self buildScoreToKeepQuery:leaderboard.descendingSortOrder];
		[scoreToKeepQuery bind:@"leaderboard_id" value:leaderboardId];
		[scoreToKeepQuery bind:@"user_id" value:userId];		
		[scoreToKeepQuery execute];
		if( scoreToKeepQuery.lastStepResult == SQLITE_ROW )
		{
			OFSqlQuery* deleteScoresQuery = [self buildDeleteScoresQuery:leaderboard.descendingSortOrder];
			NSString* scoreToKeep = [NSString stringWithFormat:@"%qi", [scoreToKeepQuery int64Value:@"keep_score"]];
			[deleteScoresQuery bind:@"leaderboard_id" value:leaderboardId];
			[deleteScoresQuery bind:@"user_id" value:userId];		
			[deleteScoresQuery bind:@"score" value:scoreToKeep];		
			[deleteScoresQuery execute];
			[deleteScoresQuery reset];
		}
		NSString* synchScore = leaderboard.allowPostingLowerScores ? sScore : [NSString stringWithFormat:@"%qi", [scoreToKeepQuery int64Value:@"high_score"]];
		[scoreToKeepQuery reset];
		
		// [adill note] this normally sets server_sync_at for all scores other
		// than this one. we want to avoid that if the leaderboard allows worse
		// scores and this score is sourced from a server sync (during bootstrap)
		// because it will mark the latest offline score as un-sync'd -- which is bad.
		if (!(leaderboard.allowPostingLowerScores && serverSynch))
		{
			//want only one pending score, but keep history of other scores
			[makeOnlyOneSynchQuery bind:@"leaderboard_id" value:leaderboardId];
			[makeOnlyOneSynchQuery bind:@"user_id" value:userId];		
			[makeOnlyOneSynchQuery bind:@"score" value:synchScore];
			[makeOnlyOneSynchQuery bind:@"server_sync_at" value:lastSyncDate];
			[makeOnlyOneSynchQuery execute];
			[makeOnlyOneSynchQuery reset];
		}
		
		//Is leaderboard part of an aggregate
		NSMutableArray* aggregateLeaderboards = [OFLeaderboardService getAggregateParents:leaderboardId];
		for (unsigned int i = 0; i < [aggregateLeaderboards count]; i++)
		{
			OFLeaderboard_Sync* parentLeaderboard = (OFLeaderboard_Sync*)[aggregateLeaderboards objectAtIndex:i];
			[OFHighScoreService localSetHighScore:(score - previousScore)
								   forLeaderboard:parentLeaderboard.resourceId
										  forUser:userId 
									  displayText:nil
									  customData:nil
									   serverDate:[NSDate date]
									addToExisting:YES];
			//[parentLeaderboard release];
		}
	}

	if (outShouldSubmit != nil)
	{
		(*outShouldSubmit) = shouldSubmitToServer;
	}

	return success;
}

+ (BOOL) synchHighScore:(NSString*)userId
{
	[sServerSynchQuery bind:@"user_id" value:userId];	
	[sServerSynchQuery execute];
	BOOL success = (sServerSynchQuery.lastStepResult == SQLITE_OK);
	[sServerSynchQuery reset];
	return success;
}

+ (OFRequestHandle*) sendPendingHighScores:(NSString*)userId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFRequestHandle* handle = nil;
    OFInvocation* chainedSuccessInvocation = [OFInvocation invocationForTarget:OFHighScoreService.sharedInstance selector:@selector(_onSetHighScore:nextInvocation:) chained:success];
	
	if ([OpenFeint isOnline] && userId != @"Invalid" && [userId longLongValue] > 0)
	{
		if([OpenFeint isLoggedIntoGameCenter] && ![OpenFeint isSynchedWithGameCenterLeaderboards])
		{
			NSString* mappingPath = [[OpenFeint getResourceBundle] pathForResource:@"OFGameCenter" ofType:@"plist"];
			NSDictionary* mappings = [[NSDictionary alloc] initWithContentsOfFile:mappingPath];
            NSMutableArray* pendingHighScores = [NSMutableArray arrayWithCapacity:10];
            
			for(NSString* leaderboardId in [mappings objectForKey:@"Leaderboards"])
			{
				NSArray* localHighScores = [OFHighScoreService getHighScoresLocal:leaderboardId];
				for(uint i = 0; i < [localHighScores count]; i++)
				{
					OFHighScore* highScore = [localHighScores objectAtIndex:i];
                    OFHighScoreBatchEntry* entry = [[OFHighScoreBatchEntry alloc] initWithLeaderboardId:leaderboardId 
                                                                                                    displayText:highScore.displayText 
                                                                                                     customData:highScore.customData 
                                                                                                           blob:highScore.blob 
                                                                                                 gameCenterDate:nil 
                                                                                                          score:highScore.score];
                    [pendingHighScores addObject:entry];
                    [entry release];
				}
			}

			handle = [OFHighScoreService 
					  batchSetHighScores:pendingHighScores
					  silently:YES
					  onSuccessInvocation:chainedSuccessInvocation
					  onFailureInvocation:failure
					  optionalMessage: nil
					  fromSynch:YES];
			[OpenFeint setSynchWithGameCenterLeaderboards:YES];
		}

		int64_t leaderboardBestScore = 0;
		NSString* leaderboardId = nil;

		NSString*lastSyncDate = [OFLeaderboardService getLastSyncDateUnixForUserId:userId];
		
		//Get leaderboards with no user_id
		[sNullUserLeaderboardsQuery execute];
		
		//associate any offline high scores to user
		[sChangeNullUserQuery bind:@"user_id" value:userId];
		[sChangeNullUserQuery execute];
		[sChangeNullUserQuery reset];
		
		for (; !sNullUserLeaderboardsQuery.hasReachedEnd; [sNullUserLeaderboardsQuery step])
		{
			leaderboardId = [NSString stringWithFormat:@"%d", [sNullUserLeaderboardsQuery intValue:@"leaderboard_id"]];
			[OFHighScoreService getPreviousHighScoreLocal:&leaderboardBestScore forLeaderboard:leaderboardId];
			[sMakeOnlyOneSynchQuery bind:@"score" value:[NSString stringWithFormat:@"%qi", leaderboardBestScore]];
			[sMakeOnlyOneSynchQuery bind:@"leaderboard_id" value:leaderboardId];
			[sMakeOnlyOneSynchQuery bind:@"user_id" value:userId];
			[sMakeOnlyOneSynchQuery bind:@"server_sync_at" value:lastSyncDate];
			[sMakeOnlyOneSynchQuery execute];
			[sMakeOnlyOneSynchQuery reset];
		}

		[sNullUserLeaderboardsQuery reset];
		
        NSMutableArray* pendingHighScores = [NSMutableArray arrayWithCapacity:5];
		[sPendingHighScoresQuery bind:@"user_id" value:userId];
		for ([sPendingHighScoresQuery execute]; !sPendingHighScoresQuery.hasReachedEnd; [sPendingHighScoresQuery step])
			{
            NSString* displayText = [sPendingHighScoresQuery stringValue:@"display_text"];
            NSString* customData = [sPendingHighScoresQuery stringValue:@"custom_data"];
            NSData* blob = [sPendingHighScoresQuery dataValue:@"blob"];
            OFHighScoreBatchEntry* entry = [[OFHighScoreBatchEntry alloc] initWithLeaderboardId:[NSString stringWithFormat:@"%d", [sPendingHighScoresQuery intValue:@"leaderboard_id"]]
                                                                                        displayText:displayText
                                                                                         customData:customData
                                                                                               blob:blob
                                                                                     gameCenterDate:nil
                                                                                              score:[sPendingHighScoresQuery int64Value:@"score"]];
            [pendingHighScores addObject:entry];
            [entry release];
			}
		[sPendingHighScoresQuery reset];

		if (pendingHighScores.count > 0)
		{
			if (NO) //(!silently)
			{
				OFLOCALIZECOMMENT("Number inside text")
				OFNotificationData* notice = [OFNotificationData dataWithText:[NSString stringWithFormat:OFLOCALSTRING(@"Submitted %i Score%s"), pendingHighScores.count, pendingHighScores.count > 1 ? "" : "s"] andCategory:kNotificationCategoryLeaderboard andType:kNotificationTypeSuccess];
				[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
			
			handle = [OFHighScoreService 
				 batchSetHighScores:pendingHighScores
						   silently:YES
                      onSuccessInvocation:chainedSuccessInvocation
                      onFailureInvocation:failure
					optionalMessage: nil
						  fromSynch:YES
			 ];
		}
	}
	
	return handle;
}

+ (BOOL) getPreviousHighScoreLocal:(int64_t*)score forLeaderboard:(NSString*)leaderboardId
{
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
	OFSqlQuery* getHighScoresQuery = [self buildGetHighScoresQuery:leaderboard.descendingSortOrder limit:1];
    [getHighScoresQuery bind:@"leaderboard_id" value:leaderboardId];
	[getHighScoresQuery bind:@"user_id" value:[OpenFeint localUser].resourceId];
	[getHighScoresQuery execute]; 
	
	BOOL foundScore = NO;
	int64_t scoreToReturn = 0;	// for historical reasons we're going to set 'score' to 0 even if we don't have a score
	if (!getHighScoresQuery.hasReachedEnd)
	{
		foundScore = YES;
		scoreToReturn = [getHighScoresQuery int64Value:@"score"];
	}
	[getHighScoresQuery reset];
	
	if (score != nil)
	{
		(*score) = scoreToReturn;
	}

	return foundScore;
}

+ (void) getHighScoresLocal:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
	OFPaginatedSeries* page = [OFPaginatedSeries paginatedSeriesFromArray:[self getHighScoresLocal:leaderboardId]];
	[success invokeWith:page];
}

+ (NSArray*) getHighScoresLocal:(NSString*)leaderboardId
{
	NSMutableArray* highScores = [NSMutableArray arrayWithCapacity:10];
	
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
	OFSqlQuery* getHighScoresQuery = [self buildGetHighScoresQuery:leaderboard.descendingSortOrder limit:10];
	[getHighScoresQuery bind:@"leaderboard_id" value:leaderboardId];
	[getHighScoresQuery bind:@"user_id" value:[OpenFeint localUser].resourceId];
	NSUInteger rank = 0;
	for ([getHighScoresQuery execute]; !getHighScoresQuery.hasReachedEnd; [getHighScoresQuery step])
	{
		OFUser* user = [OFUserService getLocalUser:[getHighScoresQuery stringValue:@"user_id"]];
		[highScores addObject:[[[OFHighScore alloc] initWithLocalSQL:getHighScoresQuery forUser:user rank:++rank] autorelease]];
	}
	[getHighScoresQuery reset];
	
	return highScores;
}

+ (OFHighScore*)getHighScoreForUser:(OFUser*)user leaderboardId:(NSString*)leaderboardId descendingSortOrder:(BOOL)descendingSortOrder
{
	OFSqlQuery* getHighScoresQuery = [self buildGetHighScoresQuery:descendingSortOrder limit:1];
	[getHighScoresQuery bind:@"leaderboard_id" value:leaderboardId];
	[getHighScoresQuery bind:@"user_id" value:user.resourceId];
	[getHighScoresQuery execute]; 
	OFHighScore* highScore = !getHighScoresQuery.hasReachedEnd ? [[[OFHighScore alloc] initWithLocalSQL:getHighScoresQuery forUser:user rank:1] autorelease] : nil;
	[getHighScoresQuery reset];
	return highScore;
}

+ (void) uploadBlob:(NSData*)blob forHighScore:(OFHighScore*)highScore
{
	if (!highScore.blobUploadParameters)
	{
		OFLog(@"Trying to upload a blob for a high score that doesn't have any upload parameters");
		return;
	}
	if (!blob)
	{
		OFLog(@"Trying to upload a nil high score blob");
		return;
	}
	[highScore _setBlob:blob];
//	OFDelegate success([OFHighScoreService sharedInstance], @selector(onBlobUploaded:));
//	OFDelegate failure([OFHighScoreService sharedInstance], @selector(onBlobUploadFailed));
	[OFCloudStorageService uploadS3Blob:blob withParameters:highScore.blobUploadParameters passThroughUserData:highScore 
                    onSuccessInvocation:[OFInvocation invocationForTarget:OFHighScoreService.sharedInstance selector:@selector(onBlobUploaded:)] 
                    onFailureInvocation:[OFInvocation invocationForTarget:OFHighScoreService.sharedInstance selector:@selector(onBlobUploadFailed)]];
}

- (void)onBlobUploaded:(OFS3Response*)response
{
	OFHighScore* highScore = (OFHighScore*)response.userParam;
	[OFHighScoreService 
		localSetHighScore:highScore.score
		forLeaderboard:highScore.leaderboardId
		forUser:highScore.user.resourceId
		displayText:highScore.displayText
		customData:highScore.customData
		blob:highScore.blob
		serverDate:[NSDate date]
		addToExisting:NO
		shouldSubmit:nil
	overrideExisting:YES];
}

- (void)onBlobUploadFailed
{
	OFLog(@"Failed to upload high score blob");
}

+ (OFSqlQuery*) buildGetHighScoresQuery:(BOOL)descendingOrder limit:(int)limit
{
	struct sqlite3* databaseHandle = nil; 
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
	}
	
	NSMutableString* query = [[[NSMutableString alloc] initWithString:@"SELECT * FROM high_scores WHERE leaderboard_id = :leaderboard_id AND user_id = :user_id ORDER BY score "] autorelease];
	NSString* orderClause = (descendingOrder ? @"DESC" : @"ASC");
	[query appendString:orderClause];
	[query appendString:[NSString stringWithFormat:@" LIMIT %i", limit]];
    return [[[OFSqlQuery alloc] initWithDb:databaseHandle query:query] autorelease];
}

+ (OFSqlQuery*) buildScoreToKeepQuery:(BOOL)descendingOrder
{
	struct sqlite3* databaseHandle = nil; 
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
	}
	
	//Book keeping save top 10 scores
	NSMutableString* query = [[[NSMutableString alloc] initWithString:@"SELECT "] autorelease];
	NSString* scoreClause = (descendingOrder ? @"min" : @"max");
	[query appendString:scoreClause];
	[query appendString:@"(x.score) AS keep_score, "];
	scoreClause = (descendingOrder ? @"max" : @"min");
	[query appendString:scoreClause];
	[query appendString:@"(x.score) AS high_score FROM (SELECT score FROM high_scores WHERE user_id = :user_id AND leaderboard_id = :leaderboard_id ORDER BY score "];
	NSString* orderClause = (descendingOrder ? @"DESC" : @"ASC");
	[query appendString:orderClause];
	[query appendString:@" LIMIT 10) AS x"];
    return [[[OFSqlQuery alloc] initWithDb:databaseHandle query:query] autorelease];
    
}

+ (OFSqlQuery*) buildDeleteScoresQuery:(BOOL)descendingOrder
{
	struct sqlite3* databaseHandle = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
	}
	
	NSMutableString* query =[[[NSMutableString alloc] initWithString:@"DELETE FROM high_scores WHERE user_id = :user_id AND leaderboard_id = :leaderboard_id AND score "] autorelease];
	NSString* comparison = (descendingOrder ? @"<" : @">");
	[query appendString:comparison];
	[query appendString:@" :score"];
    return [[[OFSqlQuery alloc] initWithDb:databaseHandle query:query] autorelease];
}

+ (OFSqlQuery*) buildSetHighScoreQuery:(BOOL)replaceExisting
{
	struct sqlite3* databaseHandle = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
	}
	
	NSMutableString* query =[[[NSMutableString alloc] initWithString:replaceExisting ? @"REPLACE " : @"INSERT OR IGNORE "] autorelease];
	[query appendString:@"INTO high_scores (user_id, leaderboard_id, score, display_text, custom_data, blob, server_sync_at) "
						"VALUES(:user_id, :leaderboard_id, :score, :display_text, :custom_data, :blob, :server_sync_at)"];
    return [[[OFSqlQuery alloc] initWithDb:databaseHandle query:query] autorelease];
}

- (NSData*)_getPendingBlobForLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	for (OFPendingBlob* pendingBlob in mPendingBlobs)
	{
		if (pendingBlob.score == score && [pendingBlob.leaderboardId isEqualToString:leaderboardId])
		{
			return pendingBlob.blob;
		}
	}
	return nil;
}

+ (NSData*)getPendingBlobForLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	return [[OFHighScoreService sharedInstance] _getPendingBlobForLeaderboard:leaderboardId andScore:score];
}

- (void)_setPendingBlob:(NSData*)blob forLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	[OFHighScoreService removePendingBlobForLeaderboard:leaderboardId];
	OFPendingBlob* pendingBlob = [[[OFPendingBlob alloc] initWithLeaderboardId:leaderboardId andScore:score andBlob:blob] autorelease];
	[mPendingBlobs addObject:pendingBlob];
}

+ (void)setPendingBlob:(NSData*)blob forLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	[[OFHighScoreService sharedInstance] _setPendingBlob:blob forLeaderboard:leaderboardId andScore:score];
}

- (void)_removePendingBlobForLeaderboard:(NSString*)leaderboardId
{
	for (OFPendingBlob* pendingBlob in mPendingBlobs)
	{
		if ([pendingBlob.leaderboardId isEqualToString:leaderboardId])
		{
			[mPendingBlobs removeObject:pendingBlob];
			return;
		}
	}
}

+ (void)removePendingBlobForLeaderboard:(NSString*)leaderboardId
{
	[[OFHighScoreService sharedInstance] _removePendingBlobForLeaderboard:leaderboardId];
}

+ (void)reportMissingBlobForHighScore:(OFHighScore*)highScore
{			
	if (!highScore)
	{
		OFLog(@"Reporting missing blob for nil high score");
		return;
	}
	
	[[self sharedInstance]
			postAction:[NSString stringWithFormat:@"high_scores/%@/invalidate_blob.xml", highScore.resourceId]
     withParameterArray:nil
     withSuccessInvocation:nil
     withFailureInvocation:nil
			 withRequestType:OFActionRequestSilent
			 withNotice:nil];
			
}

+ (OFRequestHandle*) submitHighScoreBatchArray:(NSArray*) scoreArray
                      withGameCenterDates:(NSDictionary*) dates message:(NSString*) message silently:(BOOL) silently 
                                     onSuccess:(OFInvocation*) success onFailure:(OFInvocation*) failure
		
		{
    //remove invalid scores, add gameCenter if available
    NSMutableArray* validScores = [NSMutableArray arrayWithCapacity:scoreArray.count];
    for(OFHighScoreBatchEntry* entry in scoreArray) {
        if(entry.leaderboardId && ![entry.leaderboardId isEqualToString:@""]) {
            NSDate* date = [dates objectForKey:entry.leaderboardId];
            if(date) entry.gameCenterDate = date;
            [validScores addObject:entry];
		}
    }
	
	if(!validScores.count)
	{
		//TODO Change To Assert when asserts pop alert views
		//All were invalid
		[failure invoke];
		return nil;
	}
    
    OFQueryStringWriter* newWriter = [[OFQueryStringWriter new] autorelease];
    [newWriter serializeArrayToKey:@"high_scores" elementName:@"entry" container:validScores];
    
    CLLocation* location = [OpenFeint getUserLocation];
    if (location)
    {
        double lat = location.coordinate.latitude;
        double lng = location.coordinate.longitude;
        [newWriter ioDoubleToKey:@"lat" value:lat];
        [newWriter ioDoubleToKey:@"lng" value:lng];
    }
    
    OFNotificationData* notice = [OFNotificationData dataWithText:message
                                                      andCategory:kNotificationCategoryHighScore
                                                          andType:kNotificationTypeSubmitting];
    OFRequestHandle* requestHandle = [[self sharedInstance]
                     postAction:@"client_applications/@me/high_scores.xml"
                                      withParameterArray:[newWriter getQueryParametersAsMPURLRequestParameters]
                                      withSuccessInvocation:success
                                      withFailureInvocation:failure
                     withRequestType:(silently ? OFActionRequestSilent : OFActionRequestBackground)
                     withNotice:notice];

    return requestHandle;
    
}



@end
