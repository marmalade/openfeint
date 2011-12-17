//
//  OpenFeint+NSNotification+Private.m
//  OpenFeint
//
//  Created by Benjamin Morse on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenFeint+NSNotification+Private.h"
#import "NSNotificationCenter+OpenFeint.h"

NSString* OFNSNotificationXPUserSessionCompletedSuccessfully = @"OFNSNotificationXPUserSessionCompletedSuccessfully";
NSString* OFNSNotificationXPUserSessionFailed = @"OFNSNotificationXPUserSessionFailed";
NSString* OFNSNotificationUserCreated = @"OFNSNotificationUserCreated";
NSString* OFNSNotificationExistingUserLoggedIn = @"OFNSNotificationExistingUserLoggedIn";

@implementation OpenFeint (NSNotification_Private)

+ (void)postXPUserSessionCompleted:(BOOL)success
{
    NSString* notificationName = (success ? OFNSNotificationXPUserSessionCompletedSuccessfully : OFNSNotificationXPUserSessionFailed);
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:notificationName object:nil];
}

+ (void)postUserCreated
{
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:OFNSNotificationUserCreated object:nil];
}

+ (void)postExistingUserLoggedIn
{
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:OFNSNotificationExistingUserLoggedIn object:nil];
}

@end
