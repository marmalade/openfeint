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
#import "OFSettingsParser.h"
#import "parsifal.h"
//need to build the parsifal parser

@interface OFSettingsParser ()
@property (nonatomic, retain, readwrite) NSMutableDictionary* keys;
@property (nonatomic, assign, readwrite) int state;  //0=start, 1=in config, 2=in env, 3=within a key
@property (nonatomic, retain, readwrite) NSString* partialData;
@property (nonatomic, retain, readwrite) NSString* readingElementName;
@end

#ifdef _DEBUG
static NSString* sEnvironmentKey = @"environment-debug";
#else
static NSString* sEnvironmentKey = @"environment-release";
#endif



#pragma mark Parsifal SAX Callbacks

static int StartElement(void* userdata, XMLCH const* uri, XMLCH const* localname, XMLCH const* qname, LPXMLVECTOR attributes)
{
    OFSettingsParser* parser = (OFSettingsParser*) userdata;
    NSString* elementName = [NSString stringWithUTF8String:(char const*)qname];
    switch(parser.state)
    {
        case 0:
            if([elementName isEqualToString:@"config"])
                parser.state = 1;
            break;
        case 1:
            if([elementName isEqualToString:sEnvironmentKey])
                parser.state = 2;
            break;
        case 2:
            parser.readingElementName = elementName;
            parser.partialData = @"";
            parser.state = 3;
            break;
    }
	return XML_OK;
}

static int EndElement(void* userdata, XMLCH const* uri, XMLCH const* localname, XMLCH const* qname)
{
    OFSettingsParser* parser = (OFSettingsParser*) userdata;
	NSString* elementName = [NSString stringWithUTF8String:(char const*)qname];
    switch (parser.state) {
        case 0:
            //ignoring any tags outside of config
            break;
        case 1:
            if([elementName isEqualToString:@"config"])
                parser.state = 0;
            break;
        case 2:
            if([elementName isEqualToString:sEnvironmentKey])
                parser.state = 1;
            break;
        case 3:
            if([elementName isEqualToString:parser.readingElementName])
            {
                [parser.keys setObject:parser.partialData forKey:parser.readingElementName];
                parser.state = 2;
            }
            else
            {
                NSString* errorMessage = [NSString stringWithFormat:@"Expected close for tag %@", parser.readingElementName];
                [[NSException exceptionWithName:@"XML Parsing error" reason:errorMessage userInfo:nil] raise];
            }
            break;
    }
	return XML_OK;
}

static int CharactersFound(void* userdata, XMLCH const* characters, int numCharacters)
{
    OFSettingsParser* parser = (OFSettingsParser*) userdata;
	NSString* value = [[[NSString alloc] initWithBytes:(void const*)characters length:numCharacters encoding:NSUTF8StringEncoding] autorelease];
    parser.partialData = [parser.partialData stringByAppendingString:value];
	return XML_OK;
}

static void ParsingError(LPXMLPARSER parser)
{
    [NSException exceptionWithName:@"XML Parsing error" reason:[NSString stringWithCString:(char*)parser->ErrorString encoding:NSUTF8StringEncoding] userInfo:nil];
}



#pragma mark ParsifalInputData
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






@implementation OFSettingsParser
@synthesize keys;
@synthesize state;
@synthesize partialData;
@synthesize readingElementName;

-(id) initWithData:(NSData*) data
{
    if((self = [super init]))
    {
        self.keys = [NSMutableDictionary dictionaryWithCapacity:20];
        XMLPARSER* parser;
        XMLParser_Create(&parser);
        //set the callbacks
        ParsifalInputData inputData = { data, 0 };
        parser->startElementHandler = StartElement;
        parser->endElementHandler = EndElement;
        parser->charactersHandler = CharactersFound;
        parser->errorHandler = ParsingError;
        parser->UserData = self;
        XMLParser_Parse(parser, ParsifalInputCallback, &inputData, NULL);
        XMLParser_Free(parser);
    }
    return self;
}

+(id) parserWithData:(NSData*)data
{
    return [[[self alloc] initWithData:data] autorelease];
}

+(id) parserWithFilename:(NSString*)fileName
{
    NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"xml"];
	if(![[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		// OFLog(@"OFXmlReader: Expected xml file at path %@. Not Parsing.", filePath);
		return nil;
	}
    return [self parserWithData:[NSData dataWithContentsOfFile:filePath]];    
}

-(void)dealloc
{
    self.keys = nil;
    self.partialData = nil;
    self.readingElementName = nil;
    [super dealloc];
}

@end




