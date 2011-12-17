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

#pragma once

#import <UIKit/UIKit.h>

#define DEBUG_SHOW_FULLPATH NO

typedef enum 
{
    OFLogLevelPublic = 0,
    OFLogLevelDevelopment = 60,
    OFLogLevelVerbose = 100,
} OFLogLevel;

extern int gOFLogLevel;

#define OFLogWithLevel(lvl,message,...)	{                                   \
    if (gOFLogLevel >= lvl)                                                 \
        NSLog(message, ##__VA_ARGS__);                                      \
    }

#define OFLogPublic(message,...)             OFLogWithLevel(OFLogLevelPublic, message, ##__VA_ARGS__)
#define OFLogError(message,...)              OFLogWithLevel(OFLogLevelDevelopment, message, ##__VA_ARGS__)
#define OFLogDevelopment(message,...)        OFLogWithLevel(OFLogLevelDevelopment, message, ##__VA_ARGS__)
#define OFLogVerbose(message,...)            OFLogWithLevel(OFLogLevelVerbose, message, ##__VA_ARGS__)

#define OFLog(message,...)                   OFLogWithLevel(OFLogLevelVerbose, message, ##__VA_ARGS__)



@interface OFLogging : NSObject <UIAlertViewDelegate>
{
    UIAlertView * mAlert;
    BOOL mShowAssertAlerts;
    BOOL mShowDeveloperWarnings;
}

+ (BOOL)assertFailedWithFile:(char const*)fileName
                  lineNumber:(int)lineNumber
                   condition:(const char*)condition
                     message:(NSString*)message;
+ (void)developerWarningWithMessage:(NSString*)message;
+ (void)alwaysShowDeveloperWarningWithMessage:(NSString*)message;
+ (void)setLoggingLevel:(int)level;
+ (void)setShowDeveloperWarnings:(BOOL)showDeveloperWarnings;
+ (BOOL)isDebuggerAttached;
+ (void)redirectOutputToLog;

@property (nonatomic, retain) UIAlertView * mAlert;
@property (nonatomic, assign) BOOL mShowDeveloperWarnings;
@end


#define OFDeveloperWarning(msg, ...) [OFLogging developerWarningWithMessage:[NSString stringWithFormat:msg, ## __VA_ARGS__]];

#if defined(_DEBUG)

//////////////////////////////////////////////////////////////////////////
/// Defines an assertion which breaks the debugger on the assertion line,
/// not somewhere in the assert function. 
///
/// @note	No debug box is displayed, but rather a user breakpoint notice.
//////////////////////////////////////////////////////////////////////////
#define OFAssert(cnd, msg, ...)                                                         \
    if(!(cnd))                                                                          \
    {                                                                                   \
        if ([OFLogging assertFailedWithFile:__FILE__ lineNumber:__LINE__                  \
            condition:#cnd message:[NSString stringWithFormat:msg, ## __VA_ARGS__]])    \
            kill( getpid(), SIGINT );                                                      \
    }



#else
#define OFAssert(condition, message, ...) (void)0
#endif

