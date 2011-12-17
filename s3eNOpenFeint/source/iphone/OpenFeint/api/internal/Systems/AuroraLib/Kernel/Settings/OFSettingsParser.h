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

#import <UIKit/UIKit.h>

//helper class for loading an XML settings file.  Assumes a certain structure
// <?xml version="1.0" encoding="UTF-8"?>
//<config>
//<environment-{type}>
//<key>value...

@interface OFSettingsParser : NSObject
{
@private
    int state;  //0=start, 1=in config, 2=in env, 3=within a key
    
    NSMutableDictionary* keys;  //the keys that have been read
    NSString* partialData;
    NSString* readingElementName;
}
+(id) parserWithData:(NSData*)data;
+(id) parserWithFilename:(NSString*)fileName;

@property (nonatomic, retain, readonly) NSMutableDictionary* keys;
@end
