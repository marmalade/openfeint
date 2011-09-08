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


#include "OFHighScoreBatchEntry.h"

OFHighScoreBatchEntry::OFHighScoreBatchEntry(OFISerializer* stream)
{
	serialize(stream);
}

OFHighScoreBatchEntry::OFHighScoreBatchEntry(NSString* _leaderboardId, int64_t _score, NSString* _displayText, NSString* _customData, NSData* _blob)
: leaderboardId(_leaderboardId)
, displayText(_displayText)
, customData(_customData)
, blob(_blob)
, gameCenterDate(nil)
, score(_score)
{
}

OFHighScoreBatchEntry::OFHighScoreBatchEntry()
: leaderboardId(nil)
, displayText(nil)
, customData(nil)
, blob(nil)
, gameCenterDate(nil)
, score(0)
{
}

void OFHighScoreBatchEntry::serialize(OFISerializer* stream)
{
	stream->io("leaderboard_id", leaderboardId);
	stream->io("score", score);
	if (displayText)
		stream->io("display_text", displayText);
	if (customData)
		stream->io("custom_data", customData);
	bool has_blob = (blob.get() != nil);
	stream->io("has_blob", has_blob);
    if(gameCenterDate) {
        NSTimeInterval ti = [gameCenterDate timeIntervalSince1970];
        NSUInteger intervalInt = (NSUInteger) ti;
        stream->io("gamecenter_timestamp", intervalInt);
    }
}
