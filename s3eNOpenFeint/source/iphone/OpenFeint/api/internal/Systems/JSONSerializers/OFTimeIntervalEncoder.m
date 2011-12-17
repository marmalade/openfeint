//
//  OFTimeIntervalEncoder.m
//  OpenFeint
//
//  Created by Benjamin Morse on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTimeIntervalEncoder.h"

static NSString* sTimestampKey = @"_timestamp";
static NSString* sTimeIntervalKey = @"time_delta";

@interface OFTimeIntervalEncoder ()
@property (nonatomic, retain) NSDate* timeOfEncode;
@end

@implementation OFTimeIntervalEncoder
@synthesize timeOfEncode;

+ (void)addTimestampToDictionary:(NSMutableDictionary*)dict
{
    double timestamp = [NSDate timeIntervalSinceReferenceDate];
    NSString* timestampString = [[NSNumber numberWithDouble:timestamp] stringValue];

    [dict setObject:timestampString forKey:sTimestampKey];
}

- (id)init
{
    self = [super init];
    self.timeOfEncode = [NSDate date];
    return self;
}

- (void)encodeObject:(id)object withKey:(NSString*)key
{
    if ([sTimestampKey isEqualToString:key])
    {
        double timestamp = [object doubleValue];
        NSDate* then = [NSDate dateWithTimeIntervalSinceReferenceDate:timestamp];
        double timeInterval = [self.timeOfEncode timeIntervalSinceDate:then];
        NSString* timeIntervalString = [[NSNumber numberWithDouble:timeInterval] stringValue];
        
        [super encodeObject:timeIntervalString withKey:sTimeIntervalKey];
    }
    else
    {
        [super encodeObject:object withKey:key];
    }
}

@end
