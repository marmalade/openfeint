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

//this is an ObjectiveC version of the Legacy XML/OFResource conversion routines
#import "OFResource.h"

@class OFPaginatedSeries;
@class OFXmlElement;
@class OFService;
@interface OFResource (ObjC)
+ (OFPaginatedSeries*)resourcesFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap;
- (NSString*)toResourceArrayXml; 

//these are meant to be overridden by each OFResource class
+ (NSDictionary*)dataDictionary;
+ (OFService*)getService;
+ (NSString*)getResourceName;
+ (NSString*)getResourceDiscoveredNotification;

@end
