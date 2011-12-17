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

#import "OFABTesting.h"
#import "NSString+OpenFeint.h"
#import "OFDependencies.h"
#import "OpenFeint.h"

//#define TEST_WITH_RANDOM_UID
//#define RECALCULATE_EACH_TIME

static float sTestingValue = -1.0f;

@implementation OFABTesting

+(NSUInteger)calculateDeviceNumber
{
    static BOOL sAlreadyCalculated = NO;
    static NSUInteger sValue = 0;
    
    if (!sAlreadyCalculated)
    {
        sAlreadyCalculated = YES;
        
        NSString* uid = [OpenFeint uniqueDeviceId];
        
#ifdef TEST_WITH_RANDOM_UID
        uid = [NSString stringWithFormat:@"%u", arc4random()];
#endif
#ifdef RECALCULATE_EACH_TIME
        sAlreadyCalculated = NO;
#endif
        
        NSString* sha1 = [uid sha1];
        
        if (sha1 && [sha1 length] >= 8)
        {
            NSString* lastEightDigits = [sha1 substringFromIndex:[sha1 length]-8];
            
            BOOL success = [[NSScanner scannerWithString:lastEightDigits] scanHexInt:&sValue];
            if (!success) sValue = 0;
        }
    }
    
    return sValue;
}

+(float)calculateDeviceFloatNumber
{
    static unsigned int TWENTY_EIGHT_BITS = 268435456;

    if (sTestingValue != -1.0f)
    {
        return sTestingValue;
    }
    
    unsigned int n = [self calculateDeviceNumber];
    unsigned int smaller = n % TWENTY_EIGHT_BITS;
    float value = (float)smaller/(float)TWENTY_EIGHT_BITS;
    return value;
}

+(BOOL)isWithinRangeFrom:(float)startRatio to:(float)endRatio
{
    if (startRatio > endRatio ||
        startRatio < 0.0f || startRatio > 1.0f ||
        endRatio < 0.0f || endRatio > 1.0f)
    {
        OFAssert(0, @"OFABTesting: out of range");
        return NO;
    }
    float deviceValue = [self calculateDeviceFloatNumber];
    return (deviceValue >= startRatio && deviceValue < endRatio);
}

+(BOOL)setTestingValue:(float)value
{
    if ((value >= 0.0f && value < 1.0f) || value == -1.0f)
    {
        sTestingValue = value;
        return YES;
    }
    return NO;
}

+(float)getTestingValue
{
    return sTestingValue;
}

//+(void)testUniformDistribution
//{
//    static const int VALS = 100;
//    static const int TIMES = 1000000;
//    
//    int histogram[VALS];
//    for (int i = 0; i < VALS; i++)
//    {
//        histogram[i] = 0;
//    }
//    
//    for (int i = 0; i < TIMES; i++)
//    {
//        float blah = [self calculateDeviceFloatNumber];
//        int iVal = (int)floorf(blah * (float)VALS);
//        if (iVal >= 0 && iVal < VALS)
//        {
//            histogram[iVal]++;
//        }
//        else
//        {
//            OFAssert(0, @"");
//        }
//    }
//
//    for (int i = 0; i < VALS; i++)
//    {
//        printf("%u: %u\n", i, histogram[i]);
//    }
//}


@end
