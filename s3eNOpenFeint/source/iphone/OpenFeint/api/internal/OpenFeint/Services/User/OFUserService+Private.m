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

#import "OFUserService+Private.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OFSqlQuery.h"
#import "OFOfflineService.h"
#import <sqlite3.h>
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

@interface OFUser ()
- (id)initWithLocalSQL:(OFSqlQuery*)queryRow;

@end


static OFSqlQuery* sCreateUserQuery;
static OFSqlQuery* sGetUserQuery;

@implementation OFUserService (Private)

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
	}
	
	return self;
}

- (void) dealloc
{
	OFSafeRelease(sCreateUserQuery);
	OFSafeRelease(sGetUserQuery);
	[super dealloc];
}


+ (void) setupOfflineSupport:(BOOL)recreateDB
{
	if( recreateDB )
	{
        [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
          @"DROP TABLE IF EXISTS users"]execute];
	}
    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
     @"CREATE TABLE IF NOT EXISTS users("
			   "id INTEGER NOT NULL,"
			   "name TEXT DEFAULT NULL,"
      "profile_picture_url TEXT DEFAULT NULL)"] execute];
    
    [[OFSqlQuery queryWithDb:[OpenFeint getOfflineDatabaseHandle] query:
     @"CREATE UNIQUE INDEX IF NOT EXISTS users_index "
      "ON users (id)"] execute];
	
	[OFOfflineService setTableVersion:@"users" version:1];
	
	sCreateUserQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
							@"REPLACE INTO users "
							"(id, name, profile_picture_url) "
                        "VALUES (:id, :name, :profile_picture_url)"];

	sGetUserQuery = [[OFSqlQuery alloc] initWithDb:[OpenFeint getOfflineDatabaseHandle] query:
						   @"SELECT * FROM users "
                     "WHERE id = :id"];
	
}

+ (BOOL) createLocalUser:(NSString*) userId userName:(NSString*)userName profilePictureUrl:(NSString*)profilePictureUrl
{
	[sCreateUserQuery bind:@"id" value:userId];		
	[sCreateUserQuery bind:@"name" value:userName];
	[sCreateUserQuery bind:@"profile_picture_url" value:profilePictureUrl];
	[sCreateUserQuery execute];
	BOOL success = (sCreateUserQuery.lastStepResult == SQLITE_OK);
	[sCreateUserQuery reset];
	return success;
}


+ (void) getLocalUser:(NSString*)userId onSuccessInvocation:(OFInvocation*)onSuccess onFailureInvocation:(OFInvocation*)onFailure;
{
	OFUser* user = [self getLocalUser:userId];
	if( user ) 
	{
		NSArray* resources = [[[NSArray alloc] initWithObjects:user,nil] autorelease];
		[onSuccess invokeWith:resources];
	} else {
		[onFailure invoke];
	}
}

+ (OFUser*) getLocalUser:(NSString*) userId
{
	OFUser* user = nil;
	[sGetUserQuery bind:@"id" value:userId];
	[sGetUserQuery execute];
	if (sGetUserQuery.lastStepResult == SQLITE_ROW)
	{
		user = [[[OFUser alloc] initWithLocalSQL:sGetUserQuery] autorelease];
	}
	[sGetUserQuery reset];
	
	return user;
}

@end
