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
#import "OFQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFHighScore.h"
#import "OFAbridgedHighScore.h"
#import "OFLeaderboard.h"
#import "OFNotificationData.h"
#import "OFHighScoreService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFUser.h"
#import "OFNotification.h"
#import "OFS3Response.h"
#import "OFS3UploadParameters.h"
#import "OFCloudStorageService.h"
#import "OFGameCenterHighScore.h"
#import "OFPaginatedSeries.h"
#import "OpenFeint+GameCenter.h"
#import "OFResource+ObjC.h"
#import "OFInvocation.h"
#import "OFDependencies.h"

#define kMaxHighScoreBlobSize (1024*50)

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFHighScoreService);

@interface OFSubmitHighScoreToGameCenterOnly : NSObject
{

}

- (void) submitToGameCenterOnlyWithScores:(NSArray*)entries;

@end

@implementation OFSubmitHighScoreToGameCenterOnly

- (void) submitToGameCenterOnlyWithScores:(NSArray*)entries
{	
#ifdef __IPHONE_4_1        
    for(OFHighScoreBatchEntry* entry in entries) 
    {        
		NSString* categoryId = [OpenFeint getGameCenterLeaderboardCategory:entry.leaderboardId];
		if(categoryId) 
		{
			//#ifdef to avoid warnings.
			NSString* idCopy = entry.leaderboardId;
			[OpenFeint submitScoreToGameCenter:entry.score category:categoryId withHandler:^(NSError* error)
			 {
				 if(error)
				 {
					 OFLog(@"Failed to submit leaderboard %@ to GameCenter. Error %@", idCopy, error);
				 }
			 }];
		}
	}
#endif
}
@end


@interface OFHighScoreService ()
+ (OFRequestHandle*)submitHighScoreBatch:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage;
@end

@implementation OFHighScoreService

OPENFEINT_DEFINE_SERVICE(OFHighScoreService);


- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFHighScore class] forKey:[OFHighScore getResourceName]];
	[namedResourceMap setObject:[OFAbridgedHighScore class] forKey:[OFAbridgedHighScore getResourceName]];
	[namedResourceMap setObject:[OFS3UploadParameters class] forKey:[OFS3UploadParameters getResourceName]];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFHighScoreService getPage:pageIndex forLeaderboard:leaderboardId friendsOnly:friendsOnly silently:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFHighScoreService getPage:pageIndex
				 forLeaderboard:leaderboardId
			   comparedToUserId:nil
					friendsOnly:friendsOnly
					   silently:silently
					  onSuccessInvocation:_onSuccess
					  onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex 
  forLeaderboard:(NSString*)leaderboardId 
comparedToUserId:(NSString*)comparedToUserId 
	 friendsOnly:(BOOL)friendsOnly
		silently:(BOOL)silently
         onSuccessInvocation:(OFInvocation*)_onSuccess 
         onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFHighScoreService 
		getPage:pageIndex 
		pageSize:HIGH_SCORE_PAGE_SIZE 
		forLeaderboard:leaderboardId 
		comparedToUserId:comparedToUserId
		friendsOnly:friendsOnly 
		silently:silently
        timeScope:0
		onSuccessInvocation:_onSuccess 
		onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex 
              forLeaderboard:(NSString*)leaderboardId 
            comparedToUserId:(NSString*)comparedToUserId 
                 friendsOnly:(BOOL)friendsOnly
                    silently:(BOOL)silently
                   timeScope:(NSUInteger) timeScope
         onSuccessInvocation:(OFInvocation*)_onSuccess 
         onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFHighScoreService 
            getPage:pageIndex 
            pageSize:HIGH_SCORE_PAGE_SIZE 
            forLeaderboard:leaderboardId 
            comparedToUserId:comparedToUserId
            friendsOnly:friendsOnly 
            silently:silently
            timeScope:timeScope
            onSuccessInvocation:_onSuccess 
            onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex pageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId 
            comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently 
                   timeScope:(NSUInteger) timeScope
            onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{

	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"leaderboard_id" object:leaderboardId];
	[params ioIntToKey:@"page" value:pageIndex];
	[params ioIntToKey:@"page_size" value:pageSize];
    if(timeScope > 0) [params ioIntToKey:@"interval" value:timeScope];
	
	if (friendsOnly)
	{
		BOOL friendsLeaderboard = YES;
		[params ioBoolToKey:@"friends_leaderboard" value:friendsLeaderboard];
		[params ioNSStringToKey:@"follower_id" object:@"me"];
	}
	
	if (comparedToUserId && [comparedToUserId length] > 0)
	{
		[params ioNSStringToKey:@"compared_user_id" object:comparedToUserId];
	}
	
	//For optimization on the server
	[params ioNSStringToKey:@"uses_gc" object:( [OpenFeint isLoggedIntoGameCenter] ? @"1" : @"0")];
	
	OFActionRequestType requestType = silently ? OFActionRequestSilent : OFActionRequestForeground;
	
	return [[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
	 withParameterArray:params.getQueryParametersAsMPURLRequestParameters
	 withSuccessInvocation:_onSuccess
	 withFailureInvocation:_onFailure
	 withRequestType:requestType
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded High Scores")]];
}

+ (void) getLocalHighScores:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService getHighScoresLocal:leaderboardId onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure;
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"leaderboard_id" object:leaderboardId];	
	[params ioNSStringToKey:@"near_user_id" object:@"me"];
	[params ioIntToKey:@"page_size" value:pageSize];
	
	return [[self sharedInstance]
	 getAction:@"client_applications/@me/high_scores.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
            withRequestType:silently ? OFActionRequestSilent : OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded High Scores")]];
}

+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
    return [OFHighScoreService getPageWithLoggedInUserWithPageSize:pageSize forLeaderboard:leaderboardId silently:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getPageWithLoggedInUserForLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	return [OFHighScoreService getPageWithLoggedInUserWithPageSize:HIGH_SCORE_PAGE_SIZE forLeaderboard:leaderboardId onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (OFRequestHandle*) getHighScoreNearCurrentUserForLeaderboard:(NSString*)leaderboardId andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	[params ioNSStringToKey:@"leaderboard_id" object:leaderboardId];	
	[params ioNSStringToKey:@"near_user_id" object:@"me"];
	[params ioIntToKey:@"better_count" value:betterCount];
	[params ioIntToKey:@"worse_count" value:worseCount];
	
	return [[self sharedInstance]
			getAction:@"client_applications/@me/high_scores.xml"
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
			withRequestType:OFActionRequestSilent
			withNotice:nil];
}

- (void)_uploadBlobs:(OFPaginatedSeries*)resources
{
	unsigned int highScoreCnt = [resources.objects count];
	for (unsigned int i = 0; i < highScoreCnt; i++ )
	{
		OFHighScore* highScore = [resources.objects objectAtIndex:i];
		NSData* blob = [OFHighScoreService getPendingBlobForLeaderboard:highScore.leaderboardId andScore:highScore.score];
		
		// When there is a blob to upload we don't store the score locally until the blob is done uploading. This means it doesn't get marked as synced and if 
		// something goes wrong or the game closes before uploading the blob then next time the entire highscore will get synced again and if it's still the best
		// the blob will get uploaded again.
		if (blob && highScore.blobUploadParameters)
		{
			[OFHighScoreService uploadBlob:blob forHighScore:highScore];
		}
		else
		{
			if (blob)
			{
				OFLog(@"Failed to upload blob for high score");
			}
			[OFHighScoreService 
			 localSetHighScore:highScore.score
			 forLeaderboard:highScore.leaderboardId
			 forUser:highScore.user.resourceId
			 displayText:highScore.displayText
			 customData:highScore.customData
			 blob:blob
			 serverDate:[NSDate date]
			 addToExisting:NO
			 shouldSubmit:nil
			 overrideExisting:YES];
		}
		
		[OFHighScoreService removePendingBlobForLeaderboard:highScore.leaderboardId];
	}
}

- (void)_onSetHighScore:(OFPaginatedSeries*)resources nextCall:(OFInvocation*)nextCall
{
	[nextCall invoke];
}

- (void)_onSetHighScore:(OFPaginatedSeries*)resources nextInvocation:(OFInvocation*)nextInvocation
{
	[nextInvocation invoke];
}


+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:nil forLeaderboard:leaderboardId silently:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{	
	[OFHighScoreService setHighScore:score withDisplayText:nil forLeaderboard:leaderboardId silently:silently onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText forLeaderboard:leaderboardId silently:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:nil forLeaderboard:leaderboardId silently:silently onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:customData withBlob:nil forLeaderboard:leaderboardId silently:silently deferred:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];	
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently deferred:(BOOL)deferred onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:customData withBlob:nil forLeaderboard:leaderboardId silently:silently deferred:deferred onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) setHighScore:(int64_t)score 
	  withDisplayText:(NSString*)displayText 
	   withCustomData:(NSString*)customData 
			 withBlob:(NSData*)blob
	   forLeaderboard:(NSString*)leaderboardId 
			 silently:(BOOL)silently 
			deferred:(BOOL)deferred
  onSuccessInvocation:(OFInvocation*)onSuccess 
  onFailureInvocation:(OFInvocation*)onFailure;
{
	BOOL submittedToGameCenterBecauseOFUnapproved = NO;
	
	if(![OpenFeint hasUserApprovedFeint] && [OpenFeint isLoggedIntoGameCenter])
	{
		//HACK - to make less change to the code, this hack only submits to gamecenter if we are unapproved.
        OFHighScoreBatchEntry* entry = [[OFHighScoreBatchEntry alloc] initWithLeaderboardId:leaderboardId 
                                                                                        displayText:nil 
                                                                                         customData:nil 
                                                                                               blob:nil 
                                                                                     gameCenterDate:nil 
                                                                                              score:score];
        NSArray* onlySendToGameCenterEntries = [NSArray arrayWithObject:entry];
        [entry release];
        
        
		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:onlySendToGameCenterEntries];
		
		submittedToGameCenterBecauseOFUnapproved = YES;
	}
	
	NSString* notificationText = nil;
	
	NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	BOOL shouldSubmit = YES;
	BOOL succeeded = [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:lastLoggedInUser displayText:displayText customData:customData blob:blob serverDate:nil addToExisting:NO shouldSubmit:&shouldSubmit overrideExisting:YES];
	if (shouldSubmit)
	{
		if (!deferred && [OpenFeint isOnline])
		{
			BOOL hasBlob = (blob && ([blob length] <= kMaxHighScoreBlobSize));
			if (hasBlob)
			{
				[OFHighScoreService setPendingBlob:blob forLeaderboard:leaderboardId andScore:score];
			}
			else
			{
				[OFHighScoreService removePendingBlobForLeaderboard:leaderboardId];
				if (blob)
				{
					OFLog(@"High score blob is too big (%d bytes) and will not be uploaded. Maximum size is %d bytes.", [blob length], kMaxHighScoreBlobSize);
				}
			}
			
            OFHighScoreBatchEntry* entry = [[OFHighScoreBatchEntry alloc] initWithLeaderboardId:leaderboardId displayText:displayText 
                                                                                             customData:customData blob:blob gameCenterDate:nil score:score];
            
            
			OFAssert([self sharedInstance], @"This method won't work until you initialize the service");
			[NSObject cancelPreviousPerformRequestsWithTarget:[self sharedInstance] selector:@selector(dispatchPendingScores) object:nil];            
			[[self sharedInstance] performSelector:@selector(dispatchPendingScores) withObject:nil afterDelay:0.05f];
            [[self sharedInstance]->mPendingScores addObject:entry];
			
			notificationText = OFLOCALSTRING(@"New high score!");
		}
		else
		{
			notificationText = OFLOCALSTRING(@"New high score! Saving locally.");
		}
		
		if (!silently)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:notificationText andCategory:kNotificationCategoryHighScore andType:kNotificationTypeSuccess];
			notice.imageName = @"HighScoreNotificationIcon.png";
			if([OpenFeint isOnline])
			{
				[[OFNotification sharedInstance] setDefaultBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
			else 
			{
				[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
		}
	}
	else if([OpenFeint isLoggedIntoGameCenter] && !submittedToGameCenterBecauseOFUnapproved)
	{
		//HACK - Make sure we always submit to gamecenter for time scoped leaderboard purposes (this is broken for OF).
        OFHighScoreBatchEntry* entry = [[OFHighScoreBatchEntry alloc] initWithLeaderboardId:leaderboardId displayText:displayText 
                                                                                         customData:customData blob:blob gameCenterDate:nil score:score];

		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:[NSArray arrayWithObject:entry]];
	}
	
	if (succeeded)
        [onSuccess invoke];
	else
		[onFailure invoke];
}

+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage
{
	return [OFHighScoreService batchSetHighScores:highScoreBatchEntrySeries silently:NO onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure optionalMessage:submissionMessage];
}

+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage
{
	return [OFHighScoreService batchSetHighScores:highScoreBatchEntrySeries silently:silently onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure optionalMessage:submissionMessage fromSynch:NO];
}

+ (OFRequestHandle*) batchSetHighScores:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure optionalMessage:(NSString*)submissionMessage fromSynch:(BOOL)fromSynch
{
	OFRequestHandle* requestHandle = nil;
    NSMutableArray* currentArray = [highScoreBatchEntrySeries mutableCopy];
	
	if(![OpenFeint hasUserApprovedFeint] && [OpenFeint isLoggedIntoGameCenter])
	{
		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:highScoreBatchEntrySeries];
	}

	BOOL succeeded = YES;

	if (!fromSynch)
	{
		NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
        
        NSMutableArray* newList = [NSMutableArray arrayWithCapacity:highScoreBatchEntrySeries.count];
        for(OFHighScoreBatchEntry* entry in highScoreBatchEntrySeries) {
            BOOL shouldSubmit = YES;
            succeeded = [OFHighScoreService localSetHighScore:entry.score forLeaderboard:entry.leaderboardId forUser:lastLoggedInUser 
                                                  displayText:entry.displayText customData:entry.customData serverDate:nil
                                                addToExisting:NO shouldSubmit:&shouldSubmit];
            if(!shouldSubmit) [newList addObject:entry];
        }
        [currentArray release];
        currentArray = [newList retain];
    }        
        
    for(OFHighScoreBatchEntry* entry in currentArray) {
        if(entry.blob)
            [OFHighScoreService setPendingBlob:entry.blob forLeaderboard:entry.leaderboardId andScore:entry.score];
        else {
            [OFHighScoreService removePendingBlobForLeaderboard:entry.leaderboardId];
        }

    }
    [currentArray release];
	
	if (succeeded)
	{
		requestHandle = [OFHighScoreService submitHighScoreBatch:highScoreBatchEntrySeries silently:silently onSuccessInvocation:onSuccess onFailureInvocation:onFailure optionalMessage:submissionMessage ? submissionMessage : OFLOCALSTRING(@"Submitted High Scores")];
	}
	else
	{
		[onFailure invoke];
	}
	
	return requestHandle;
}

- (void)dispatchPendingScores
{
//	OFDelegate submitSuccessDelegate(self, @selector(_onSetHighScore:nextCall:));
	[OFHighScoreService submitHighScoreBatch:mPendingScores silently:YES 
                         onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_onSetHighScore:nextCall:)]
                         onFailureInvocation:nil optionalMessage:nil];
    [mPendingScores removeAllObjects];
}

+ (OFRequestHandle*)submitHighScoreBatch:(NSArray*)highScoreBatchEntrySeries silently:(BOOL)silently onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure optionalMessage:(NSString*)submissionMessage
{
	OFRequestHandle* requestHandle = nil;

//	OFDelegate uploadDelegate = OFDelegate([OFHighScoreService sharedInstance], @selector(_uploadBlobs:));
    OFInvocation* uploadInvocation = [OFInvocation invocationForTarget:OFHighScoreService.sharedInstance selector:@selector(_uploadBlobs:)];
	
    OFGameCenterHighScore* highScore = [[OFGameCenterHighScore alloc] initWithSeries:highScoreBatchEntrySeries];
    highScore.silently = silently;
    highScore.message = submissionMessage;
    requestHandle = [highScore submitOnSuccessInvocation:onSuccess onFailureInvocation:onFailure onUploadBlobInvocation:uploadInvocation];
    [highScore release];
    
	return requestHandle;
}

+ (void) getAllHighScoresForLoggedInUserInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure optionalMessage:(NSString*)submissionMessage
{
	OFNotificationData* notice = [OFNotificationData dataWithText:submissionMessage ? submissionMessage : @"Downloaded High Scores" 
													  andCategory:kNotificationCategoryHighScore
														  andType:kNotificationTypeDownloading];
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	BOOL acrossLeaderboards = YES;
	[params ioBoolToKey:@"across_leaderboards" value:acrossLeaderboards];
	[params ioNSStringToKey:@"user_id" object:@"me"];
	
	[[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:notice];
}

+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	[OFHighScoreService getHighScoresFromLocation:origin radius:radius pageIndex:pageIndex forLeaderboard:leaderboardId userMapMode:nil onSuccessInvocation:_onSuccess onFailureInvocation:_onFailure];
}

+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId userMapMode:(NSString*)userMapMode onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
	
	BOOL geolocation = YES;
	[params ioBoolToKey:@"geolocation" value:geolocation];

	[params ioIntToKey:@"page" value:pageIndex];
	
	[params ioNSStringToKey:@"leaderboard_id" object:leaderboardId];
	if (radius != 0)
		[params ioIntToKey:@"radius" value:radius];
	
	if (origin)
	{
		CLLocationCoordinate2D coord = origin.coordinate;
		[params ioDoubleToKey:@"lat" value: coord.latitude];
		[params ioDoubleToKey:@"lng" value: coord.longitude];
	}
	
	if (userMapMode)
	{
		[params ioNSStringToKey:@"map_me" object:userMapMode];
	}

	[[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
     withParameterArray:params.getQueryParametersAsMPURLRequestParameters
     withSuccessInvocation:_onSuccess
     withFailureInvocation:_onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:nil];	
}

+ (OFRequestHandle*) getDistributedHighScoresAtPage:(NSInteger)pageIndex 
										   pageSize:(NSInteger)pageSize 
										 scoreDelta:(NSInteger)scoreDelta
										 startScore:(NSInteger)startScore
									 forLeaderboard:(NSString*)leaderboardId 
                                onSuccessInvocation:(OFInvocation*)_onSuccess 
                                onFailureInvocation:(OFInvocation*)_onFailure;
{
	return [[self sharedInstance] 
			getAction:[NSString stringWithFormat:@"leaderboards/%@/high_scores/range/%d/%d/%d/%d.xml", leaderboardId, startScore, scoreDelta, pageIndex, pageSize]
            withParameterArray:nil
            withSuccessInvocation:_onSuccess
            withFailureInvocation:_onFailure
			withRequestType:OFActionRequestSilent
			withNotice:nil];
}


+ (OFRequestHandle*) downloadBlobForHighScore:(OFHighScore*)highScore onSuccessInvocation:(OFInvocation*)_onSuccess onFailureInvocation:(OFInvocation*)_onFailure
{
	OFRequestHandle* request = nil;
	if (![highScore hasBlob])
	{
		OFLog(@"Trying to download the blob for a high score that doesn't have a blob attached to it.");
		[_onFailure invoke];
	}
	else
	{	
		if (highScore.blob)
		{
			[_onSuccess invokeWith:highScore];
		}
		else
		{
            
            request = [OFCloudStorageService downloadS3Blob:highScore.blobUrl 
                                        passThroughUserData:highScore
                                        onSuccessInvocation:[OFInvocation invocationForTarget:[OFHighScoreService sharedInstance] selector:@selector(onBlobDownloaded:nextCall:) chained:_onSuccess]
                                        onFailureInvocation:[OFInvocation invocationForTarget:[OFHighScoreService sharedInstance] selector:@selector(onBlobFailedDownloading:nextCall:) chained:_onFailure]];
		}
	}
	
	return request;
}

- (void) onBlobDownloaded:(OFS3Response*)response nextCall:(OFInvocation*)nextCall
{
	OFHighScore* highScore = (OFHighScore*)response.userParam;
	if (highScore)
	{
		[highScore _setBlob:response.data];
	}
	[nextCall invokeWith:highScore];
}

- (void) onBlobFailedDownloading:(OFS3Response*)response nextCall:(OFInvocation*)nextCall
{
	if (response && response.statusCode == 404)
	{
		[OFHighScoreService reportMissingBlobForHighScore:(OFHighScore*)response.userParam];
	}
	[nextCall invoke];
}

@end

