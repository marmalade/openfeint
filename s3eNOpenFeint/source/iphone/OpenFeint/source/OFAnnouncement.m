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

#import "OFResourceField.h"
#import "OFAnnouncement.h"
#import "OFAnnouncementService+Private.h"
#import "OFForumPost.h"
#import "OFPaginatedSeries.h"
#import "OpenFeint+UserOptions.h"
#import "OFForumService.h"
#import "OFTableSectionDescription.h"
#import "OpenFeint+NSNotification.h"
#import "OFXPRequest.h"
#import "OFDependencies.h"

#import "NSDateFormatter+OpenFeint.h"
#import "OFResource+ObjC.h"

static id sharedDelegate = nil;
@interface OFAnnouncementService()
- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap;
+ (OFRequestHandle*)getIndexOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (void)recentAnnouncementsForApplication:(NSString*)applicationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
+ (OFRequestHandle*)downloadAnnouncementsOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
@end


@interface OFAnnouncement (Private)
	+ (void)_downloadAnnouncementsSuccess:(OFPaginatedSeries*)resources sortType:(NSNumber*)numberSortType;
	+ (void)_downloadAnnouncementsFailure;
    - (id)initWithParams:(NSDictionary*)params;
	- (void)_getPostsSuccess:(OFPaginatedSeries*)resources;
	- (void)_getPostsFailure;
+ (void)_sendAnnouncementsSuccessFromPaginatedSeries:(OFPaginatedSeries*)resources withSortType:(EAnnouncementSortType)sortType;
@end

@implementation OFAnnouncement

@synthesize body, originalPostDate, isImportant, isUnread, linkedClientApplicationId;

+ (void)setDelegate:(id<OFAnnouncementDelegate>)delegate
{
	sharedDelegate = delegate;
	
	if(sharedDelegate == nil)
	{
		[OFRequestHandlesForModule cancelAllRequestsForModule:[OFAnnouncement class]];
	}
}

+ (OFRequestHandle*)downloadAnnouncementsAndSortBy:(EAnnouncementSortType)sortType;
{
	OFRequestHandle* handle = nil;
	
//	handle = [OFAnnouncementService downloadAnnouncementsOnSuccess:OFDelegate(self, @selector(_downloadAnnouncementsSuccess:sortType:), [NSNumber numberWithUnsignedInt:(uint)sortType])
//															 onFailure:OFDelegate(self, @selector(_downloadAnnouncementsFailure))];
    handle = [OFAnnouncementService downloadAnnouncementsOnSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadAnnouncementsSuccess:sortType:) userParam:[NSNumber numberWithUnsignedInt:(uint) sortType]]

                                                         onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_downloadAnnouncementsFailure)]];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFAnnouncement class]];
	return handle;
}

+ (OFAnnouncement*)announcementWithParams:(NSDictionary*)params
{
    return [[[OFAnnouncement alloc] initWithParams:params] autorelease];
}

- (id)initWithParams:(NSDictionary*)params
{
    NSString * announcementId = [params objectForKey:@"announcement_id"];
    self = [super initWithId:announcementId];
    if (self)
    {
        body = [[params objectForKey:@"announcement_body"] retain];
        isUnread = YES;
    }
    return self;
}

- (void)markAsRead
{
	if(isUnread)
	{
        NSString* url = [NSString stringWithFormat:@"/xp/games/%@/announcements/%@/read", [OpenFeint clientApplicationId], self.resourceId];
        OFXPRequest* req = [OFXPRequest putRequestWithPath:url andBodyString:@""];
        req.requiresUserSession = YES;
        [req execute];

		if([OFAnnouncementService sharedInstance].unseenAnnouncementCount > 0)
		{
			//This really should always be the case...
			[OFAnnouncementService sharedInstance].unseenAnnouncementCount--;
            [OpenFeint setUnreadAnnouncementCount:[OFAnnouncementService sharedInstance].unseenAnnouncementCount];
		}
		[OpenFeint setLastAnnouncementDateForLocalUser:originalPostDate];
		isUnread = NO;
        
        [OpenFeint postAnnouncementRead];
	}
}

- (OFRequestHandle*)getPosts
{
	OFRequestHandle* handle = nil;
	handle = [OFForumService getPostsForThread:self.resourceId
										  page:1
                           onSuccessInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getPostsSuccess:)]
                           onFailureInvocation:[OFInvocation invocationForTarget:self selector:@selector(_getPostsFailure)]];
//									 onSuccess:OFDelegate(self, @selector(_getPostsSuccess:))
//									 onFailure:OFDelegate(self, @selector(_getPostsFailure))];
	
	[OFRequestHandlesForModule addHandle:handle forModule:[OFAnnouncement class]];
	return handle;
}

+ (void)_downloadAnnouncementsSuccess:(OFPaginatedSeries*)resources sortType:(NSNumber*)numberSortType
{
	[self _sendAnnouncementsSuccessFromPaginatedSeries:resources withSortType:(EAnnouncementSortType)[numberSortType unsignedIntValue]];
}

+ (void)_downloadAnnouncementsFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailDownloadAnnouncements)])
	{
		[sharedDelegate didFailDownloadAnnouncements];
	}
}

-(void) _getPostsSuccess:(OFPaginatedSeries*)resources
{
	NSArray* posts = [[[NSArray alloc] initWithArray:resources.objects] autorelease];
	
	if([posts count] > 0)
	{
		if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didGetPosts:OFAnnouncement:)])
		{
			if([posts count] > 1)
			{
				//Omit the first post, this is the "body"
				NSRange range;
				range.location = 1;
				range.length = [posts count] - 1;
				[sharedDelegate didGetPosts:[posts subarrayWithRange:range] OFAnnouncement:self];
			}
			else
			{
				//Otherwise, the replies are empty.
				[sharedDelegate didGetPosts:[[[NSArray alloc] init] autorelease] OFAnnouncement:self];
			}

		}
	}
	else
	{
		[self _getPostsFailure];
	}

}

-(void) _getPostsFailure
{
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didFailGetPostsOFAnnouncement:)])
	{
		[sharedDelegate didFailGetPostsOFAnnouncement:self];
	}
	
}

+ (void)_sendAnnouncementsSuccessFromPaginatedSeries:(OFPaginatedSeries*)resources withSortType:(EAnnouncementSortType)sortType
{
	NSArray* tableDesc = [[[NSArray alloc] initWithArray:resources.objects] autorelease];
	
	NSMutableArray* announcements[2] = {nil, nil};
	if ([tableDesc count] < 2) {
        return;
    }
	for(uint i = 0; i < 2; i++)
	{
		OFTableSectionDescription* table = [tableDesc objectAtIndex:i];
		announcements[i] = [[[NSMutableArray alloc] initWithArray:table.page.objects] autorelease];
		if(sortType == EAnnouncementSortType_CREATION_DATE)
		{
			[announcements[i] sortUsingSelector:@selector(compareByCreationDate:)];
		}
		else if(sortType == EAnnouncementSortType_UPDATE_DATE)
		{
			[announcements[i] sortUsingSelector:@selector(compareByUpdateDate:)];
		}
	}
	
	if(sharedDelegate && [sharedDelegate respondsToSelector:@selector(didDownloadAnnouncementsAppAnnouncements:devAnnouncements:)])
	{
		[sharedDelegate didDownloadAnnouncementsAppAnnouncements:announcements[0] devAnnouncements:announcements[1]];
	}
}

#pragma mark Boilerplate

- (void)dealloc
{
	OFSafeRelease(body);
	OFSafeRelease(linkedClientApplicationId);
    OFSafeRelease(originalPostDate);
	[super dealloc];
}

#pragma mark Public Methods

- (NSComparisonResult)compareByCreationDate:(OFAnnouncement*)announcement
{
	return [announcement.originalPostDate compare:originalPostDate];
}

- (NSComparisonResult)compareByUpdateDate:(OFAnnouncement*)announcement
{
	return [announcement.date compare:date];
}

- (NSComparisonResult)compareByCreationDateAndSticky:(OFAnnouncement*)announcement
{
	if((isSticky && announcement.isSticky) || (!isSticky && !announcement.isSticky))
	{
		return [self compareByCreationDate:announcement];
	}
	else
	{
		//If I am sticky, then I should be put at the front of the array (acending),
		//else if announcement is sticky (which it must be in this case if I am not
		//due to the above if), then put me behind announcement (descending).
		return (isSticky ? NSOrderedAscending : NSOrderedDescending);
	}
	
}

#pragma mark XML Data Field Methods

- (void)setPost:(OFForumPost*)firstPost
{
	OFSafeRelease(body);
	body = [firstPost.body retain];
}

- (void)setLinkedClientApplicationId:(NSString*)value
{
	OFSafeRelease(linkedClientApplicationId);
	linkedClientApplicationId = [value retain];
}

- (void)setOriginalPostDateFromString:(NSString*)value
{
	OFSafeRelease(originalPostDate);
	originalPostDate = [[[NSDateFormatter railsFormatter] dateFromString:value] retain];
}

- (void)setImportantFromString:(NSString*)value
{
	isImportant = [value boolValue];
}

- (NSString*)importantAsString
{
	return isImportant ? @"true" : @"false";
}

- (void)setUnreadFromString:(NSString*)value
{
	isUnread = [value boolValue];
}

- (NSString*)unreadAsString
{
	return isUnread ? @"true" : @"false";
}

#pragma mark OFResource

+ (OFService*)getService
{
	return [OFAnnouncementService sharedInstance];
}


+ (NSString*)getResourceName
{
	return @"discussion";
}

+ (NSString*)getResourceDiscoveredNotification
{
	return nil;
}

+ (NSDictionary*)dataDictionary
{
    static NSDictionary*sDataDictionary = nil;
    if(!sDataDictionary)
    {
        NSMutableDictionary* combinedDictionary = [NSMutableDictionary dictionaryWithDictionary:[super dataDictionary]];
        
        NSDictionary* local = [NSDictionary dictionaryWithObjectsAndKeys:
[OFResourceField nestedResourceSetter:@selector(setPost:) getter:nil klass:[OFForumPost class]], @"post",
[OFResourceField fieldSetter:@selector(setImportantFromString:) getter:@selector(importantAsString)], @"important",
[OFResourceField fieldSetter:@selector(setUnreadFromString:) getter:@selector(unreadAsString)], @"unread",
[OFResourceField fieldSetter:@selector(setLinkedClientApplicationId:) getter:@selector(linkedClientApplicationId)], @"linked_client_application_id",
[OFResourceField fieldSetter:@selector(setOriginalPostDateFromString:)], @"created_at",
        nil];
        [combinedDictionary addEntriesFromDictionary:local];
        sDataDictionary = [[NSDictionary dictionaryWithDictionary:combinedDictionary] retain];
    }
    return sDataDictionary;
}

@end
