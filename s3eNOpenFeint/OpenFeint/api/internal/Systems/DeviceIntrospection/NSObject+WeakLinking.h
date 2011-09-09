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

#ifdef __IPHONE_3_0
	#define OF_OS_3_ENUM_ARG(enumName) (id)enumName
#else
	#define OF_OS_3_ENUM_ARG(enumName) (id)0
#endif

@interface NSObject (WeakLinking)

- (void)trySet:(NSString*)firstDottedProperty elseSet:(NSString*)elseDottedProperty with:(id)value;
- (id)  tryGet:(NSString*)firstDottedProperty elseGet:(NSString*)elseDottedProperty;

- (void)trySet:(NSString*)firstDottedProperty with:(id)firstValue elseSet:(NSString*)elseDottedProperty with:(id)secondValue;
		
@end
