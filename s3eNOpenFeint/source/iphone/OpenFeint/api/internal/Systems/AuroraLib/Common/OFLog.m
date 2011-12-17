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

#import "OFDependencies.h"
#import "OFLog.h"

#import <sys/sysctl.h>
#import <unistd.h>
#import "OFSettings.h"

static OFLogging * gInstance = nil;
int gOFLogLevel = OFLogLevelPublic;


@interface OFLogging()
- (BOOL)assertFailedWithFile:(char const*)fileName
                  lineNumber:(int)lineNumber
                   condition:(const char*)condition
                     message:(NSString*)message;
@end



@implementation OFLogging

@synthesize mAlert, mShowDeveloperWarnings;

+ (OFLogging*)Instance
{
    if (!gInstance)
    {
        gInstance = [[OFLogging alloc] init];
    }
    return gInstance;
}

+ (void)setLoggingLevel:(int)level
{
    gOFLogLevel = level;
}

+ (void)setShowDeveloperWarnings:(BOOL)showDeveloperWarnings
{
    [self Instance].mShowDeveloperWarnings = showDeveloperWarnings;
}

+ (BOOL)assertFailedWithFile:(char const*)fileName
                  lineNumber:(int)lineNumber
                   condition:(const char*)condition
                     message:(NSString*)message
{
    return [[self Instance] assertFailedWithFile:fileName
                                      lineNumber:lineNumber
                                       condition:condition
                                         message:message];
}

+ (BOOL)isDebuggerAttached
{
    int mib[4];
    size_t bufSize = 0;
    int local_error = 0;
    struct kinfo_proc kp;
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    bufSize = sizeof (kp);
    if ((local_error = sysctl(mib, 4, &kp, &bufSize, NULL, 0)) < 0)
    {
        NSLog(@"Error determining if program is traced.");
        return FALSE;
    }
    
    return ((kp.kp_proc.p_flag & P_TRACED) == P_TRACED);
}

+ (void)redirectOutputToLog
{
    NSDateFormatter *dateFormat=[[[NSDateFormatter alloc] init] autorelease];
    [dateFormat setDateFormat:@"MM-dd-yyyy-hh-mm-ss"];
    NSString* dateString = [dateFormat stringFromDate:[NSDate date]];
    
    NSString* filePath = [OFSettings savePathForFile:[NSString stringWithFormat:@"log/console-%@.log", dateString]];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES attributes:nil error:nil];                
    freopen([filePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

- (void)showDeveloperWarningAlert:(NSString*)message
{
    [[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"OpenFeint Developer Warning") 
                                 message:message
                                delegate:self 
                       cancelButtonTitle:OFLOCALSTRING(@"OK") 
                       otherButtonTitles:nil] autorelease] show];
}

+ (void)developerWarningWithMessage:(NSString*)message
{
    if ([self Instance].mShowDeveloperWarnings)
    {
        [[self Instance] performSelectorOnMainThread:@selector(showDeveloperWarningAlert:) withObject:message waitUntilDone:NO];
    }
}

+ (void)alwaysShowDeveloperWarningWithMessage:(NSString*)message
{
    [[self Instance] performSelectorOnMainThread:@selector(showDeveloperWarningAlert:) withObject:message waitUntilDone:NO];
}



- (id)init
{
    self = [super init];
    if (self)
    {
        mShowAssertAlerts = YES;
        mShowDeveloperWarnings = NO;
    }
    return self;
}


- (void)dealloc
{
    mAlert.delegate = nil;
    self.mAlert = nil;
    [super dealloc];
}

- (void)showAssertAlert:(NSString*)message
{
    self.mAlert = [[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"Assert Failed") 
                                              message:message
                                             delegate:self 
                                    cancelButtonTitle:OFLOCALSTRING(@"Ignore All Asserts") 
                                    otherButtonTitles:OFLOCALSTRING(@"OK"),
                    nil] autorelease];
    [self.mAlert show];
}

- (BOOL)assertFailedWithFile:(char const*)fileName
                  lineNumber:(int)lineNumber
                   condition:(const char*)condition
                     message:(NSString*)message
{
    NSString *filePath, *nsCondition;
    
    // Build the path string
    filePath = [[NSString alloc] initWithBytes:fileName length:strlen(fileName) encoding:NSUTF8StringEncoding];
    nsCondition = [[NSString alloc] initWithBytes:condition length:strlen(condition) encoding:NSUTF8StringEncoding];
    
    NSString * fullMessage = [NSString stringWithFormat:@"(%s:%d) Assert failed: \"%@\" \"%@\"", [((DEBUG_SHOW_FULLPATH) ? filePath : [filePath lastPathComponent]) UTF8String], lineNumber, nsCondition, message];
    NSLog(@"%@", fullMessage);
    
    [filePath release];
    [nsCondition release];
    
    if (![OFLogging isDebuggerAttached])
    {
        if (!mAlert && mShowAssertAlerts)
        {
            [self performSelectorOnMainThread:@selector(showAssertAlert:) withObject:fullMessage waitUntilDone:NO];
            
            // I would like to block this thread here until the alert view is closed by the user,
            // but this isn't feasible.  If this happens in the main thread, we would block
            // the main thread and the alert view would not display or receive touch events.
        }
        return NO;
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        mShowAssertAlerts = NO;
    }
    self.mAlert = nil;
}




@end

