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
#pragma once

#import <Foundation/Foundation.h>

@interface OFResourceField : NSObject {
    SEL mSetter;
    SEL mGetter;
    Class mResourceClass;
    BOOL mIsArray;    
}
+(id) fieldSetter:(SEL)setter;
+(id) fieldSetter:(SEL)setter getter:(SEL)getter;
+(id) nestedResourceSetter:(SEL)setter getter:(SEL)getter klass:(Class) resourceClass;
+(id) nestedResourceArraySetter:(SEL) setter;
+(id) nestedResourceArraySetter:(SEL) setter getter:(SEL)getter;
//note that isArray(YES) and klass are mutually exclusive
-(id) initWithSetter:(SEL) setter getter:(SEL) getter klass:(Class) resourceClass isArray:(BOOL) isArray;
-(NSString*)description;


@property (nonatomic, readonly) SEL setter;
@property (nonatomic, readonly) SEL getter;
@property (nonatomic, retain, readonly) Class resourceClass;
@property (nonatomic, readonly) BOOL isArray;
@end
