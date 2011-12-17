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
#import "OFSqlQuery.h"
#import "OFDependencies.h"
#import <sqlite3.h>
@interface OFSqlQuery()
@property (nonatomic, readwrite) int lastStepResult;
@property (nonatomic, retain) NSString* queryString;
@property (nonatomic) struct sqlite3* dbHandle;
@property (nonatomic) struct sqlite3_stmt* compiledStatement;
@property (nonatomic, retain) NSArray* columnIndex;
-(int)parameterIndex:(NSString*)parameterName;
-(int)columnIndex:(NSString*)columnName;
@end

#define SQLITE_CHECK(x,doAssert)											\
{																	\
int result = x;											\
if(doAssert && result != SQLITE_OK)									\
{																\
OFLog(@"Failed executing: %s", ""#x);			\
OFLog(@"   Result code: %d", result);			\
OFLog(@"   %s", sqlite3_errmsg(self.dbHandle));	\
OFLog(@"   in query: %@", self.queryString);		\
[[NSException exceptionWithName:@"SQL Error" \
reason:@"Failed execution" \
userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, @"sqlQuery",\
          self.queryString, @"queryString",\
          [NSString stringWithCString:sqlite3_errmsg(self.dbHandle) encoding:NSUTF8StringEncoding], @"message",\
          [NSNumber numberWithInt:self.lastStepResult], @"result",\
          nil]] raise];\
}																\
}

@implementation OFSqlQuery
@synthesize lastStepResult = mLastStepResult;
@synthesize queryString = mQueryString;
@synthesize dbHandle = mDBHandle;
@synthesize compiledStatement = mCompiledStatement;
@synthesize columnIndex = mColumnIndex;
+(id) queryWithDb:(struct sqlite3*) dbHandle query:(NSString*) query
{
    return [[[self alloc] initWithDb:dbHandle query:query doAssert:YES] autorelease];
}

+(id) queryWithDb:(struct sqlite3*) dbHandle query:(NSString*) query doAssert:(BOOL)doAssert
{
    return [[[self alloc] initWithDb:dbHandle query:query doAssert:doAssert] autorelease];
}
-(id) initWithDb:(struct sqlite3*) dbHandle query:(NSString*) query
{
    return [self initWithDb:dbHandle query:query doAssert:YES];
}


-(id) initWithDb:(struct sqlite3*) dbHandle query:(NSString*) query doAssert:(BOOL)doAssert
{
    if((self = [super init]))
    {
        self.dbHandle = dbHandle;
        self.queryString = query;
        self.lastStepResult = SQLITE_OK;

        int prepareResult;
        
        static const int prepareMaxRetries = 20;
        int prepareNumberOfRetries = 0;
        BOOL retry = NO;
        do {
            retry = NO;
            prepareResult = sqlite3_prepare_v2(self.dbHandle, self.queryString.UTF8String, self.queryString.length, &mCompiledStatement, NULL);
            
            if (prepareResult != SQLITE_OK && prepareResult != SQLITE_ERROR)
            {
                OFLog(@"Database busy");
                if (prepareNumberOfRetries < prepareMaxRetries)
                {
                    prepareNumberOfRetries++;
                    retry = YES;
                    [NSThread sleepForTimeInterval:0.2];
                }
            }
        } while (retry);
        
        SQLITE_CHECK(prepareResult, doAssert);
        
        
        
//        SQLITE_CHECK(sqlite3_prepare_v2(self.dbHandle, self.queryString.UTF8String, self.queryString.length, &mCompiledStatement, NULL), doAssert);
        
        const unsigned int numColumnsInRow = sqlite3_column_count(self.compiledStatement);
        NSMutableArray* tempColumns = [NSMutableArray arrayWithCapacity:numColumnsInRow];
        for(unsigned int i=0; i<numColumnsInRow; ++i)
            [tempColumns addObject:[NSString stringWithCString:sqlite3_column_name(self.compiledStatement, i) encoding:NSUTF8StringEncoding]];
        self.columnIndex = tempColumns;
    }
    return self;
}


-(void) dealloc
{
    if(self.compiledStatement)
    {
        sqlite3_finalize(self.compiledStatement);
    }
    self.columnIndex = nil;
    self.queryString = nil;
    [super dealloc];
}

-(void) bind:(NSString*) parameter value:(NSString*) value
{
    SQLITE_CHECK(sqlite3_bind_text(self.compiledStatement, [self parameterIndex:parameter], [value UTF8String], -1, SQLITE_TRANSIENT),YES);
}
-(void) bind:(NSString*) parameter value:(const void*) value size:(unsigned int) size
{
	SQLITE_CHECK(sqlite3_bind_blob(self.compiledStatement, [self parameterIndex:parameter], value, size, SQLITE_TRANSIENT), YES);
}

-(BOOL)execute
{
    return [self executeWithAssert:YES];
}

-(BOOL) executeWithAssert:(BOOL) doAssert
{	self.lastStepResult = sqlite3_step(self.compiledStatement);
    
	if( doAssert && 
	   !(self.lastStepResult == SQLITE_OK ||
		 self.lastStepResult == SQLITE_ROW || 
		 self.lastStepResult == SQLITE_DONE ||
		 self.lastStepResult == SQLITE_CONSTRAINT))
	{
		OFLog(@"Failed stepping query");
		OFLog(@"   Result code: %d", self.lastStepResult);	
		OFLog(@"   %s", sqlite3_errmsg(self.dbHandle));
		OFLog(@"   in query: %@", self.queryString);	
        
        const char* sqlMessage = sqlite3_errmsg(self.dbHandle);
        NSString* messageObj = [NSString stringWithCString:sqlMessage encoding:NSUTF8StringEncoding];
        [[NSException exceptionWithName:@"SQL Error" 
                                 reason:@"Failed stepping query" 
                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, @"sqlQuery",
                                        self.queryString, @"queryString",                                        
                                        messageObj, @"message",
                                        [NSNumber numberWithInt:self.lastStepResult], @"result",
                                        nil]] raise];
	}
    
	if(self.lastStepResult == SQLITE_DONE)
	{
        [self reset];
	}
    
	return self.lastStepResult == SQLITE_ROW;
    
}

-(void)reset 
{
	sqlite3_reset(self.compiledStatement);
	self.lastStepResult = SQLITE_OK;
}

-(void)step
{
    [self executeWithAssert:YES];
}

-(BOOL) hasReachedEnd
{
    return self.lastStepResult != SQLITE_ROW;

}

-(double)doubleValue:(NSString*) columnName
{
    return sqlite3_column_double(self.compiledStatement, [self columnIndex:columnName]);
}
-(int)intValue:(NSString*) columnName
{
    return sqlite3_column_int(self.compiledStatement, [self columnIndex:columnName]);
}
-(int64_t) int64Value:(NSString*) columnName
{
    return sqlite3_column_int64(self.compiledStatement, [self columnIndex:columnName]);
}
-(int)boolValue:(NSString*) columnName  //the return type matches the older version
{
    return [self intValue:columnName] != 0;
}
-(NSString*) stringValue:(NSString*) columnName
{
    char* text = (char*)sqlite3_column_text(self.compiledStatement, [self columnIndex:columnName]);
    if(text && text[0])
        return [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    else 
        return @"";
}
-(NSData*)dataValue:(NSString*)columnName
{
    int columnIndex = [self columnIndex:columnName];
    const void* blobData = sqlite3_column_blob(mCompiledStatement, columnIndex);
    if(blobData)
        return [NSData dataWithBytes:blobData length:sqlite3_column_bytes(self.compiledStatement, columnIndex)];
    else 
        return nil;
}

-(int)parameterIndex:(NSString*)parameterName
{
	unsigned int index =	sqlite3_bind_parameter_index(self.compiledStatement, [[NSString stringWithFormat:@":%@", parameterName] UTF8String]);
    if(index == 0)
    {
        OFLog(@"Invalid named parameter :%@ in query: %@", parameterName, self.queryString);

        [[NSException exceptionWithName:@"SQL Error" 
                                 reason:@"Invalid named parameter" 
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, @"sqlQuery",
                                         self.queryString, @"queryString",
                                         parameterName, @"parameterName",
                                         nil]] raise];
    }
    return index;
}

-(int)columnIndex:(NSString*)columnName
{
    for(int i=0; i<self.columnIndex.count; ++i)
    {
        if([[self.columnIndex objectAtIndex:i] isEqualToString:columnName]) return i;
    }
	OFLog(@"Invalid column name %@ in result-set for: %@", columnName, self.queryString);
    [[NSException exceptionWithName:@"SQL Error" 
                             reason:@"Invalid column name" 
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, @"sqlQuery",
                                     self.queryString, @"queryString",
                                     columnName, @"columnName",
                                     nil]] raise];
    return -1;
}

@end
