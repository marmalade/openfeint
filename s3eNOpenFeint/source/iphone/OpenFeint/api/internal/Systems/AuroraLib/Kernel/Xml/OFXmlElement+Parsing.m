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

#import "OFXmlElement+Parsing.h"
#import "parsifal.h"
#import "OFDependencies.h"

@interface OFXmlElement ()
@property (nonatomic, retain, readwrite) NSMutableArray* children;
@property (nonatomic, retain) NSMutableArray* loadingElements;
@end


@interface OFXmlElementParser : NSObject
{
    NSMutableArray* mLoadingElements;
    OFXmlElement* mRootObject;
}
@property (nonatomic, retain) NSMutableArray* loadingElements;
@property (nonatomic, retain) OFXmlElement* rootObject;
@end

@implementation OFXmlElementParser
@synthesize rootObject= mRootObject;
@synthesize loadingElements = mLoadingElements;

-(id)init
{
    if((self = [super init]))
    {
        self.loadingElements = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

-(void) dealloc
{
    self.loadingElements = nil;
    self.rootObject = nil;
    [super dealloc];
}

@end


#pragma mark Parsifal SAX Callbacks
static int StartElement(void* userdata, XMLCH const* uri, XMLCH const* localname, XMLCH const* qname, LPXMLVECTOR attributes)
{
	NSString* elementName = [NSString stringWithUTF8String:(char const*)qname];
    OFXmlElement* newElement = [OFXmlElement elementWithName:elementName];
	
	if (attributes->length > 0)
	{
		LPXMLRUNTIMEATT attribute = NULL;
		NSMutableDictionary* attributeDictionary = [NSMutableDictionary dictionaryWithCapacity:attributes->length];
		
		int i = 0;
		for (; i < attributes->length; ++i)
		{
			attribute = (LPXMLRUNTIMEATT)XMLVector_Get(attributes, i);
			[attributeDictionary 
             setObject:[NSString stringWithUTF8String:(char const*)attribute->value] 
             forKey:[NSString stringWithUTF8String:(char const*)attribute->qname]];
		}
		
		newElement.attributes = attributeDictionary;
	}
    OFXmlElementParser* parserData = (OFXmlElementParser*) userdata;
    if(parserData.loadingElements.count)
    {
        OFXmlElement* currentElement = parserData.loadingElements.lastObject;
        [currentElement addChild:newElement];
    }
    else
    {
        parserData.rootObject = newElement;
    }
    
    [parserData.loadingElements addObject:newElement];
	return XML_OK;
}

static int EndElement(void* userdata, XMLCH const* uri, XMLCH const* localname, XMLCH const* qname)
{
    OFXmlElementParser* parserData = (OFXmlElementParser*) userdata;
    OFXmlElement* currentElement = parserData.loadingElements.lastObject;
    if(!currentElement.value) currentElement.value = @"";
    
    [parserData.loadingElements removeLastObject];
	return XML_OK;
}

static int CharactersFound(void* userdata, XMLCH const* characters, int numCharacters)
{
    OFXmlElementParser* parserData = (OFXmlElementParser*) userdata;

	OFXmlElement* element = [parserData.loadingElements lastObject];
    
	NSString* value = [[NSString alloc] initWithBytes:(void const*)characters length:numCharacters encoding:NSUTF8StringEncoding];
    if(element.value)
    {
        element.value = [element.value stringByAppendingString:value];
    }
    else 
    {
        element.value = value;
    }
    
    [value release];
    
	return XML_OK;
}

static void ParsingError(LPXMLPARSER parser)
{
	OFLog(@"Error parsing XML: %s", parser->ErrorString);
}

#pragma mark Parsifal Input Callback

typedef struct
{
	NSData* data;
	unsigned int offset;
} ParsifalInputData;

static int ParsifalInputCallback(BYTE *buf, int cBytes, int *cBytesActual, void *inputData)
{
	ParsifalInputData* data = (ParsifalInputData*)inputData;
	
	unsigned int desiredBytes = (unsigned int)cBytes;
	
	unsigned char* bytes = (unsigned char*)[data->data bytes];
	unsigned int length = [data->data length];
	
	unsigned int consumedBytes = MIN((length - data->offset), desiredBytes);
	memcpy(buf, bytes + data->offset, consumedBytes);
	
	data->offset += consumedBytes;
	(*cBytesActual) = consumedBytes;
	return consumedBytes < desiredBytes;
}


@implementation OFXmlElement (Parsing)
+ (id)parseElementsFromData:(NSData*)data
{
    OFXmlElementParser* parserData = [OFXmlElementParser new];
    LPXMLPARSER parser = NULL;
    XMLParser_Create(&parser);
    
    parser->startElementHandler = StartElement;
    parser->endElementHandler = EndElement;
    parser->charactersHandler = CharactersFound;
    parser->errorHandler = ParsingError;	
    parser->UserData = parserData;
    
    ParsifalInputData inputData;
    inputData.data = data;
    inputData.offset = 0;
	
    XMLParser_Parse(parser, ParsifalInputCallback, &inputData, NULL);
    
    XMLParser_Free(parser);
    
    OFXmlElement* root = [parserData.rootObject retain];    
    [parserData release];
    return [root autorelease];
}

@end
