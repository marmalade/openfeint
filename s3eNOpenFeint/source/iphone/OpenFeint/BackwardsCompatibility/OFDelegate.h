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

#include "OFRetainedPtr.h"
#include "NSObject+WeakLinking.h"

/// @note Any interfaces that wish to receive callbacks from an OFDelegate must implement the OFCallbackable protocol.
///		  If you forget, the error will be caught with a runtime assertion.
@class OFInvocation;
class OFDelegate
{
public:
	OFDelegate();
	~OFDelegate();

	OFDelegate(OFDelegate const& otherDelegate);
	OFDelegate& operator=(const OFDelegate& otherDelegate);

	OFDelegate(NSObject* target, SEL selector);	
	OFDelegate(NSObject* target, SEL selector, NSObject* userParam);
    
    OFDelegate(OFInvocation* invocation);

	OFDelegate(NSObject* target, SEL selector, NSThread* targetThread);
	OFDelegate(NSObject* target, SEL selector, NSThread* targetThread, NSObject* userParam);
	
	void invoke(NSObject* parameter = 0) const;
	void invoke(NSObject* parameter, NSTimeInterval afterDelay) const;

	BOOL isValid() const;
	
	NSObject * getTarget() const { return mTarget; }
	SEL getSelector() const { return mSelector; }
    OFInvocation* getInvocation() const;  //returns an ObjC OFInvocation with equivalent functionality

private:
	NSObject* mTarget;
	NSObject* mUserParam;
	NSThread* mTargetThread;
	SEL mSelector;
};
