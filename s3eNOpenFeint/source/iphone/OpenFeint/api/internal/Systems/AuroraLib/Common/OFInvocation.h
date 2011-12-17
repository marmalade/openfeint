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

//A wrapper for simplifying creation and use of NSInvocation objects
//supports creation of chained invocation objects.
@interface OFInvocation : NSObject {
    id target;
    SEL selector;
    OFInvocation* chainedInvocation;
    NSThread* thread;
    id userParam;
}

+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector;
+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector userParam:(id) userParam;
+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector thread:(NSThread*) thread;
+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector userParam:(id) userParam thread:(NSThread*) thread;


//these are used internally to OpenFeint
+(OFInvocation*) invocationForTarget:(id)target selector:(SEL)selector chained:(OFInvocation*) chained;
+(OFInvocation*) invocationForTarget:(id)target selector:(SEL) selector chained:(OFInvocation*) chained thread:(NSThread*) thread;

@property (nonatomic, retain, readonly) id target;
@property (nonatomic, assign, readonly) SEL selector;
@property (nonatomic, retain, readonly) OFInvocation* chainedInvocation;
@property (nonatomic, retain, readonly) NSThread* thread;
@property (nonatomic, retain, readonly) id userParam;

-(void) invoke;
-(void) invokeWith:(NSObject*)object;
-(void) invokeWith:(NSObject*)object afterDelay:(NSTimeInterval) afterDelay;

@end
