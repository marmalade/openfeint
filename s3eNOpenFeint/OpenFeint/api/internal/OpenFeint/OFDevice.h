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

#import "OFJsonCoder.h"

@class OFParentalControls;

@interface OFDevice	: NSObject< OFJsonCoding >
{
	NSArray* users;
	OFParentalControls* parentalControls;
}

@property (nonatomic, retain, readonly) NSArray* users;
@property (nonatomic, retain, readwrite) OFParentalControls* parentalControls; //OFEnable/DisableParentalControlsController set this.

@end
