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

#import "OFInvocation.h"

//support class for posting achievements to GameCenter and/or OpenFeint
@class OFRequestHandle;
@class OFPaginatedSeries;
@interface OFGameCenterAchievement : NSObject {
    NSArray* achievementIds;
	NSArray* percentsComplete; //indecies map to achievementID indecies
    OFPaginatedSeries* openFeintPage;
    BOOL batch;
    BOOL sync;
    NSUInteger openFeintStatus;  //0=not used, 1=sending, 2=finished, 3=errored
    NSUInteger gameCenterStatus;
    NSUInteger gameCenterCount;
    OFInvocation* mSuccessInvocation;
    OFInvocation* mFailureInvocation; 
}

//set all the properties and then call submit
-(OFRequestHandle*)submitOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;

@property (nonatomic, retain) NSArray* achievementIds;
@property (nonatomic, retain) NSArray* percentsComplete;
@property (nonatomic, retain) OFPaginatedSeries* openFeintPage;
@property (nonatomic) BOOL batch;
@property (nonatomic) BOOL sync;

@end



@interface OFSubmitAchievementToGameCenterOnly : NSObject
{
	uint achievementStillToRecieveCallbackCount;
	BOOL encounteredAnError;
	BOOL sentFailure;
}

- (void) submitToGameCenterOnlyWithIds:(NSArray*)achievementIds andPercentCompletes:(NSArray*)percentCompletes
                   onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;

@end

