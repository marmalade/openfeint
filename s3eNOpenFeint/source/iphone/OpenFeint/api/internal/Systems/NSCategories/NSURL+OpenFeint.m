////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "NSUrl+OpenFeint.h"
#import "OFSettings.h"

@implementation NSURL(OpenFeint)

+ (NSURL*)OFURLWithString:(NSString*)URLString
{
 	BOOL absoluteUrl = [URLString hasPrefix:@"http"] || [URLString hasPrefix:@"www"];
    NSURL* pathUrl;
    if(absoluteUrl)
        pathUrl = [NSURL URLWithString:URLString];
    else {
        pathUrl = [NSURL URLWithString:URLString relativeToURL:[NSURL URLWithString:[[OFSettings instance] getSetting:@"server-url"]]];
    }
    
    return pathUrl;
}

@end

