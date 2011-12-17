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


//macro to mark user facing strings that may need localization
//error logs are not included
#define OFLOCALSTRING(x) x
//just a note to indicate something the localizer should know
#define OFLOCALIZECOMMENT(x) 

#import <TargetConditionals.h>

#ifdef __OBJC__
    //////////////////////////////////////////////////////////////////////////
    /// Defines a macro which releases an objective C class and sets it to nil
    //////////////////////////////////////////////////////////////////////////
    #define OFSafeRelease(ocObject) [ocObject release]; \
        ocObject = nil;

    #import "OFInvocation.h"
    #import "OFLog.h"
#endif
