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
#import "OFResource+ObjC.h"
#import "OFPaginatedSeries.h"
#import "OFXmlResourceWriter.h"
#import "OFXmlElement.h"
#import "OFResourceField.h"
#import "OFTableSectionDescription.h"
#import "OFPaginatedSeries.h"
#import "OFPaginatedSeriesHeader.h"
#import "OFServerNotification.h"
#import "objc/runtime.h"
#import "OFControllerHelpersCommon.h"
#import "OFDependencies.h"
@interface OFResource ()
- (void)populateFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap;
@property (nonatomic, retain) NSString* resourceId;
@end


@implementation OFResource (ObjC)

+(OFResource*)buildIdentifiedResource:(OFXmlElement*)element 
                        resourceClass:(Class)resourceClass withMap:(NSDictionary*)resourceNameMap
{
    OFResource* resourceInstance = [[class_createInstance(resourceClass, 0) init] autorelease];
	if(![resourceInstance isKindOfClass:[OFResource class]])
	{
		OFLog(@"'%s' does not inherit from '%s' and cannot be loaded as a resource.", class_getName(resourceClass), class_getName([OFResource class]));
		return nil;
	}
    [resourceInstance populateFromXml:element withMap:resourceNameMap];
    return resourceInstance;
}

+ (OFResource*)parseResource:(OFXmlElement*)element withMap:(NSDictionary*)resourceNameMap
{
    Class resourceType = [resourceNameMap objectForKey:element.name];
    if(resourceType)
    {
        return [OFResource buildIdentifiedResource:element resourceClass:resourceType withMap:resourceNameMap];
    }
    else {
		OFLog(@"'%s' is attempting to read an unknown resource type: '%@'", class_getName([self class]), element.name);
		return nil;
    }
}


+ (NSMutableArray*)parseNestedResourceArrayFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap
{
    NSMutableArray* resources = [NSMutableArray arrayWithCapacity:data.children.count];
    for(OFXmlElement* child in data.children)
    {
        OFResource* resourceInstance = [OFResource parseResource:child withMap:resourceNameMap];
        if(resourceInstance)
        {
            [resources addObject:resourceInstance];
        }
    }
    return resources;
}

+ (OFPaginatedSeries*)paginatedSeriesFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap
{
    OFPaginatedSeries* resourcePage = [OFPaginatedSeries paginatedSeries];
    for(OFXmlElement* child in data.children)
    {
        if([child.name isEqualToString:@"table_meta_data"])
        {
            resourcePage.tableMetaDataObjects = [OFResource parseNestedResourceArrayFromXml:child withMap:resourceNameMap];
        }
        else if([child.name isEqualToString:[OFPaginatedSeriesHeader getElementName]])
        {
            resourcePage.header = [OFPaginatedSeriesHeader paginationHeaderWithXml:child];
        }
        else if([child.name isEqualToString:[OFServerNotification getResourceName]])
        {
			//Note that we are stripping out the Server Notification here and it is not stored in the paginated series.
			//In particular, if this resource was sent by the presence system, the server notification will never make it to the 
			//dispatching for the presence system, but the Notification will be shown because this strips it out and shows it now.
            NSDictionary* serverDictionary = [NSDictionary dictionaryWithObject:OFServerNotification.class forKey:OFServerNotification.getResourceName];
			
			id serverNotificationResource = [OFResource parseResource:child withMap:serverDictionary];
			[[OFNotification sharedInstance] showServerNotification:serverNotificationResource];
        }
        else
        {
            OFResource* resourceInstance = [OFResource parseResource:child withMap:resourceNameMap];
            if(resourceInstance)
            {
                [resourcePage addObject:resourceInstance];
            }
        }

    }
    return resourcePage;
}


+ (OFTableSectionDescription*)parseSection:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap
{
    //need to clean OFTableSectionDescription
    OFTableSectionDescription* section = [[OFTableSectionDescription new] autorelease];
    section.title = [[data getChildWithName:@"name"] value];
    section.identifier = [[data getChildWithName:@"identifier"] value];
    section.page = [OFResource paginatedSeriesFromXml:[data getChildWithName:@"resources"] withMap:resourceNameMap];
    return section;
}

+ (OFPaginatedSeries*)resourcesFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap
{
    if([data.name isEqualToString:@"resource_sections"])
    {
        OFPaginatedSeries* sections = [OFPaginatedSeries paginatedSeries];
        for(OFXmlElement* child in data.children)
        {
            if([child.name isEqualToString:@"table_meta_data"])
            {
                sections.tableMetaDataObjects = [OFResource parseNestedResourceArrayFromXml:child withMap:resourceNameMap];
            }
            else if([child.name isEqualToString:@"resource_section"])
            {
                [sections addObject:[OFResource parseSection:child withMap:resourceNameMap]];
            }
        }
        return sections;
    }
    else {
        return [OFResource paginatedSeriesFromXml:data withMap:resourceNameMap];
    }
}


- (void)populateFromXml:(OFXmlElement*)data withMap:(NSDictionary*)resourceNameMap
{
    NSDictionary* dataMap = [[self class] dataDictionary];
    
    for(OFXmlElement*child in data.children)
    {
        if([child.name isEqualToString:@"id"]) 
        {
            self.resourceId = child.value;
        }
        else 
        {
            OFResourceField* field = [dataMap objectForKey:child.name];
            if(field)            
            {
                id childObject;
                if(field.isArray)
                {
                    childObject = [OFResource parseNestedResourceArrayFromXml:child withMap:resourceNameMap];
                }
                else if(field.resourceClass)
                {
                    childObject = [OFResource buildIdentifiedResource:child resourceClass:field.resourceClass withMap:resourceNameMap];
                }
                else 
                {
                    childObject = child.value;
                }
                [self performSelector:field.setter withObject:childObject];
            }
        }
    }
}


- (NSString*)toResourceArrayXml
{
	return [OFXmlResourceWriter xmlStringFromResources:[NSArray arrayWithObject:self]];
}

//these should never get called, they are here to keep the compiler from sending warnings about missing functions
//resources will define these if they need them
+ (NSDictionary*)dataDictionary { 
    ASSERT_OVERRIDE_MISSING;
    return nil;
}
+ (OFService*)getService { return nil; }
+ (NSString*)getResourceName { return nil; }
+ (NSString*)getResourceDiscoveredNotification { return nil; }



@end
