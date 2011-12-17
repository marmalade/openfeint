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

#import "OFHighScoreBatchEntry.h"


@implementation OFHighScoreBatchEntry
@synthesize leaderboardId;
@synthesize gameCenterDate;
@synthesize blob;
@synthesize score;
@synthesize displayText;
@synthesize customData;

-(id)initWithLeaderboardId:(NSString*) _leaderboardId 
               displayText:(NSString*) _displayText
                customData:(NSString*) _customData 
                      blob:(NSData*) _blob 
            gameCenterDate:(NSDate*) _gameCenterDate
                     score:(int64_t) _score {
    if((self = [super init])) {
        leaderboardId = [_leaderboardId retain];
        displayText = [_displayText retain];
        customData = [_customData retain];
        blob = [_blob retain];
        gameCenterDate = [_gameCenterDate retain];
        score = _score;
    }   
    return self;
}

-(void) dealloc {
    [leaderboardId release];
    [displayText release];
    [customData release];
    [blob release];
    [gameCenterDate release];
    [super dealloc];
}

- (void) serializeToOFISerializer:(id<OFISerializer>) serializer {
    [serializer ioNSStringToKey:@"leaderboard_id" object:leaderboardId];
    [serializer ioInt64ToKey:@"score" value:score];
    if(displayText)
        [serializer ioNSStringToKey:@"display_text" object:displayText];
    if(customData)
        [serializer ioNSStringToKey:@"custom_data" object:customData];
    [serializer ioBoolToKey:@"has_blob" value:(blob != nil)];
    if(gameCenterDate) {
        NSTimeInterval ti = [gameCenterDate timeIntervalSince1970];
        NSUInteger intervalInt = (NSUInteger) ti;
        [serializer ioIntToKey:@"gamecenter_timestamp" value:intervalInt];

    }
    
}

@end
