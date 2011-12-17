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

#import "OFISerializer.h"

@interface OFHighScoreBatchEntry : NSObject<OFISerialized> {
    NSString* leaderboardId;
    NSString* displayText;
    NSString* customData;
    NSData* blob;
    NSDate* gameCenterDate;
    int64_t score;
}
@property (nonatomic, retain, readonly) NSString* leaderboardId;
@property (nonatomic, retain, readonly) NSString* displayText;
@property (nonatomic, retain, readonly) NSString* customData;
@property (nonatomic, retain, readonly) NSData* blob;
@property (nonatomic, retain) NSDate* gameCenterDate;
@property (nonatomic, readonly) int64_t score;

-(id)initWithLeaderboardId:(NSString*) leaderboardId 
               displayText:(NSString*) displayText
                customData:(NSString*) customData 
                      blob:(NSData*) blob 
            gameCenterDate:(NSDate*) gameCenterDate
                     score:(int64_t) score;
- (void) serializeToOFISerializer:(id<OFISerializer>) serializer;


@end
