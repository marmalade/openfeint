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


@interface OFInvocationDelay : NSObject
{
    NSInvocation* invocation;
    NSTimeInterval delay;
}
+(id) invocationDelayWithInvocation:(NSInvocation*) invocation thread:(NSThread*) thread delay:(NSTimeInterval) delay;
-(id) initWithInvocation:(NSInvocation*) _invocation thread:(NSThread*) thread delay:(NSTimeInterval) _delay;
-(void) invokeWithDelay;
-(void) invoke;
@end

@implementation OFInvocationDelay
+(id) invocationDelayWithInvocation:(NSInvocation*) invocation thread:(NSThread*) thread delay:(NSTimeInterval) delay
{
    return [[[OFInvocationDelay alloc] initWithInvocation:invocation thread:thread delay:delay] autorelease];
}
-(id) initWithInvocation:(NSInvocation*) _invocation thread:(NSThread*) thread delay:(NSTimeInterval) _delay
{
    if((self = [super init])) 
    {
        invocation = [_invocation retain];
        delay = _delay;
        if(thread == [NSThread currentThread]) {
            [self invokeWithDelay];
        }
        else {
            [self performSelector:@selector(invokeWithDelay) onThread:thread withObject:nil waitUntilDone:NO];
        }
    }
    return self;
}

-(void) invokeWithDelay {
    if(delay)
        [self performSelector:@selector(invoke) withObject:nil afterDelay:delay];
    else {
        [self invoke];
    }

}

-(void) invoke {
    [invocation invoke];
}

-(void) dealloc 
{
    [invocation release];
    [super dealloc];
}

@end


@interface OFInvocation ()
@property (nonatomic, retain) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, retain) OFInvocation* chainedInvocation;
@property (nonatomic, retain) NSThread* thread;
@property (nonatomic, retain) id userParam;
@end


@implementation OFInvocation
@synthesize target;
@synthesize selector;
@synthesize chainedInvocation;
@synthesize thread;
@synthesize userParam;

-(id) initWithTarget:(id)_target selector:(SEL) _selector chained:(OFInvocation*) _chained userParam:(id) _userParam thread:(NSThread*) _thread
{
    if((self = [super init])) 
    {
        self.target = _target;
        self.selector = _selector;
        self.chainedInvocation = _chained;
        self.userParam = _userParam;
        self.thread = _thread;
    }
    return self;
}

-(void)dealloc 
{
    self.target = nil;
    self.chainedInvocation = nil;
    self.thread = nil;
    self.userParam = nil;
    [super dealloc];
}


+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector 
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:nil userParam:nil thread:[NSThread mainThread]] autorelease];
}

+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector thread:(NSThread*) thread 
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:nil userParam:nil thread:thread] autorelease];
}

+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector userParam:(id) userParam 
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:nil userParam:userParam thread:[NSThread mainThread]] autorelease];
}

+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector userParam:(id) userParam thread:(NSThread*) thread
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:nil userParam:userParam thread:thread] autorelease];
}


+(OFInvocation*) invocationForTarget:(id)target selector:(SEL)selector chained:(OFInvocation*) chained 
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:chained userParam:nil thread:[NSThread mainThread]] autorelease];
}

+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector chained:(OFInvocation*) chained thread:(NSThread*) thread
{
    return [[[OFInvocation alloc] initWithTarget:target selector:selector chained:chained userParam:nil thread:thread] autorelease];
}

-(void) invoke 
{    
    [self invokeWith:nil afterDelay:0];
}

-(void) invokeWith:(NSObject*)object
{    
    [self invokeWith:object afterDelay:0];
}

-(void) invokeWith:(NSObject*)object afterDelay:(NSTimeInterval) afterDelay
{
    if (!self.target)
    {
        return;
    }
    
    NSMethodSignature* sig = [self.target methodSignatureForSelector:self.selector];
    if(!sig)
    {
        NSLog(@"OFInvocation error: object %@ does not have selector %s", self.target, sel_getName(self.selector));
        return;
    }
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = self.target;
    invocation.selector = self.selector;
    [invocation retainArguments];

    if(sig.numberOfArguments > 2)
    {
        [invocation setArgument:&object atIndex:2];
    }
    if(sig.numberOfArguments > 3) 
    {
        if(userParam)
            [invocation setArgument:&userParam atIndex:3];
        else {
            [invocation setArgument:&chainedInvocation atIndex:3];
        }

    }
    [OFInvocationDelay invocationDelayWithInvocation:invocation thread:thread delay:afterDelay];
}


@end
