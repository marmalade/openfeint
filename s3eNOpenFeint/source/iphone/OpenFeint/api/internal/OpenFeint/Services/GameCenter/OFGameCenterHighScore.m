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

#import "OFGameCenterHighScore.h"
#import "OpenFeint+GameCenter.h"
#import "OFNotification.h"
#import "OFHighScoreService+Private.h"
#import "OFPaginatedSeries.h"
#import "OFInvocation.h"
#import "OFDependencies.h"

static NSUInteger STATUS_UNUSED = 0;
static NSUInteger STATUS_PENDING = 1;
static NSUInteger STATUS_SUCCESS = 2;
static NSUInteger STATUS_ERROR = 3;

@interface OFGameCenterHighScore ()

-(void) openFeintSuccess:(OFPaginatedSeries*)resources; 
-(void) openFeintFailure;
-(void)testCompletion:(OFPaginatedSeries*)resources;
-(void)testCompletion;
@property (nonatomic, retain) OFInvocation* successInvocation;
@property (nonatomic, retain) OFInvocation* failureInvocation;
@property (nonatomic, retain) OFInvocation* uploadBlobInvocation;
@end



@implementation OFGameCenterHighScore
@synthesize silently;
@synthesize message;
@synthesize successInvocation = mSuccessInvocation;
@synthesize failureInvocation = mFailureInvocation;
@synthesize uploadBlobInvocation = mUploadBlobInvocation;

-(id)initWithSeries:(NSArray*) _scores {
    if((self = [super init])) {
        scores = [_scores retain];
    }
    return self;
}

-(void)dealloc {
    self.successInvocation = nil;
    self.failureInvocation = nil;
    self.uploadBlobInvocation = nil;
    [scores release];
    [super dealloc];
}

-(OFRequestHandle*)submitOnSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure onUploadBlobInvocation:(OFInvocation*)onUploadBlob
{
    self.successInvocation = onSuccess;
    self.failureInvocation = onFailure;
	self.uploadBlobInvocation = onUploadBlob;
    OFRequestHandle* handle = nil;
    
    if(scores.count == 0) {
        [ onSuccess invoke];
		if (!self.silently && self.message)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:self.message andCategory:kNotificationCategoryHighScore andType:kNotificationTypeSuccess];
			[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
		}
        return nil;
    }
    
    
    openFeintStatus = STATUS_UNUSED;
    gameCenterStatus = STATUS_UNUSED;
    gameCenterCount = 0;

    NSMutableDictionary* datesPerScore = [NSMutableDictionary dictionaryWithCapacity:scores.count];
    
#ifdef __IPHONE_4_1    
    if([OpenFeint isLoggedIntoGameCenter]) {
        //send each of them to the GameCenter processor, maybe they'll set a date
        for(OFHighScoreBatchEntry* entry in scores) 
        {
            NSString*categoryId = [OpenFeint getGameCenterLeaderboardCategory:entry.leaderboardId];
            if(categoryId) {
                ++gameCenterCount;
                gameCenterStatus = STATUS_PENDING;
				//#ifdef to avoid warnings.
                NSString* idCopy = entry.leaderboardId;
                NSDate* date = [OpenFeint submitScoreToGameCenter:entry.score category:categoryId withHandler:^(NSError* error) {
                    --gameCenterCount;
                    if(error) {
                        OFLog(@"Failed to submit leaderboard %@ to GameCenter. Error %@", idCopy, error);
                        gameCenterStatus = STATUS_ERROR;
                    }
                    else {
                        if(!gameCenterCount && gameCenterStatus == STATUS_PENDING)
                            gameCenterStatus = STATUS_SUCCESS;
						OFLog(@"Leaderboard successful");
                    }
                    [self testCompletion];
                }]; 
                if(date) [datesPerScore setObject:date forKey:entry.leaderboardId];
            }
        }
    }
#endif    
    openFeintStatus = STATUS_PENDING;
    handle = [OFHighScoreService submitHighScoreBatchArray:scores withGameCenterDates:datesPerScore
                                                   message:self.message ? self.message : @"Submitted High Scores" silently:self.silently
                                                 onSuccess:[OFInvocation invocationForTarget:self selector:@selector(openFeintSuccess:)] 
                                                 onFailure:[OFInvocation invocationForTarget:self selector:@selector(openFeintFailure)]
              ];    
    
    return handle;
}
-(void) openFeintSuccess:(OFPaginatedSeries*)resources
{
    if(openFeintStatus == STATUS_PENDING) openFeintStatus = STATUS_SUCCESS;
    else NSAssert(0, @"High score state is invalid");
    [self.uploadBlobInvocation invokeWith:resources];
    [self testCompletion:resources];
}

-(void) openFeintFailure {
    if(openFeintStatus == STATUS_PENDING) openFeintStatus = STATUS_ERROR;
    else NSAssert(0, @"High score state is invalid");
    [self testCompletion];
}

-(void) testCompletion 
{
	[self testCompletion:nil];
}

-(void) testCompletion:(OFPaginatedSeries*)resources;
{
	//if(openFeintStatus == STATUS_SUCCESS && resources)
	//{
	//	uploadBlobDelegate.invoke(resources);
//		uploadBlobDelegate = OFDelegate(); //Clear it out, only upload once.
//	}
	
    if(openFeintStatus == STATUS_PENDING ||gameCenterStatus == STATUS_PENDING) return;  //still in progress
    if(openFeintStatus != STATUS_ERROR && gameCenterStatus != STATUS_ERROR) 
	{
        [self.successInvocation invokeWith:resources];
    }
    else {
        [self.failureInvocation invoke];
    }
}

@end
