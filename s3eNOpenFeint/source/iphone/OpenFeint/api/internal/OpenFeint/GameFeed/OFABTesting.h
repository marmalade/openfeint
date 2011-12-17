//  Copyright 2009-2011 Aurora Feint, Inc.
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

#import <Foundation/Foundation.h>

@interface OFABTesting : NSObject

// Each device is given a number from 0 to 1.
// This will return YES if the local device's number lies between these ranges.
// This can be visualized as a pie chart.  All devices are evenly distributed through the pie chart.
// If a particular test wishes to isolate all the devices in the first quarter of the pie chart, it will
// test with:
// isWithinRangeFrom:0 to:0.25
+(BOOL)isWithinRangeFrom:(float)startRatio to:(float)endRatio;

+(BOOL)setTestingValue:(float)value;
+(float)getTestingValue;

@end
