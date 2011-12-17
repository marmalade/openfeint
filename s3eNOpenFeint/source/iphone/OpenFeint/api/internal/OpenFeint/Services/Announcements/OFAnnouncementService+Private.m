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

#import "OFAnnouncementService+Private.h"
#import "OFService+Private.h"
#import "OFQueryStringWriter.h"
#import "OFPaginatedSeries.h"
#import "OFNavigationController.h"
#import "OFTableSectionDescription.h"

#import "OFAnnouncement.h"
#import "OFForumPost.h"
#import "OFAnnouncementDetailController.h"

#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+NSNotification.h"

#import "NSDateFormatter+OpenFeint.h"
#import "OFResource+ObjC.h"
#import "OFDependencies.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFAnnouncementService);

@implementation OFAnnouncementService

@synthesize announcements, unseenAnnouncementCount;

OPENFEINT_DEFINE_SERVICE(OFAnnouncementService);

- (void)dealloc
{
	OFSafeRelease(announcements);
	[super dealloc];
}

- (OFPaginatedSeries*)_combineSections:(OFPaginatedSeries*)page
{
	OFPaginatedSeries* sorted = [OFPaginatedSeries paginatedSeries];
	
	if ([page count] > 0)
	{
		if ([[page objectAtIndex:0] isKindOfClass:[OFTableSectionDescription class]])
		{
			for (OFTableSectionDescription* section in page)
			{
				[sorted.objects addObjectsFromArray:section.page.objects];
			}
		}
		else
		{
			[sorted.objects addObjectsFromArray:page.objects];
		}
	}
	
	return sorted;
}

- (void) populateKnownResourceMap:(NSMutableDictionary*)namedResourceMap
{
	[namedResourceMap setObject:[OFAnnouncement class] forKey:[OFAnnouncement getResourceName]];
	[namedResourceMap setObject:[OFForumPost class] forKey:[OFForumPost getResourceName]];
}

+ (OFRequestHandle*)downloadAnnouncementsOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
	NSString* clientApplicationId = [OpenFeint clientApplicationId];
	NSDate* lastAnnouncementDate = [OpenFeint lastAnnouncementDateForLocalUser];
    
	OFQueryStringWriter* params = [OFQueryStringWriter writer];
    [params ioNSStringToKey:@"since" object:( [[NSDateFormatter httpFormatter] stringFromDate:lastAnnouncementDate])];
    
	return [[self sharedInstance] 
            _performAction:[NSString stringWithFormat:@"client_applications/%@/forums/announcements.xml", clientApplicationId]
            withParameterArray:params.getQueryParametersAsMPURLRequestParameters
            withHttpMethod:@"GET"
            withSuccessInvocation:success
            withFailureInvocation:failure
            withRequestType:OFActionRequestSilent
            withNotice:nil
            requiringAuthentication:NO];
}
+ (OFRequestHandle*)getIndexOnSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure
{
    [success invokeWith:OFAnnouncementService.sharedInstance->announcements];
//	success.invoke([OFAnnouncementService sharedInstance]->announcements);
    return nil;
}
+ (void)recentAnnouncementsForApplication:(NSString*)applicationId onSuccessInvocation:(OFInvocation*)success onFailureInvocation:(OFInvocation*)failure;
{
//	OFDelegate chainedSuccess([OFAnnouncementService sharedInstance], @selector(_combineSectionsAndSort:nextCall:), success.getInvocation());
    
	[[self sharedInstance]
     getAction:[NSString stringWithFormat:@"client_applications/%@/forums/announcements.xml", applicationId] 
     withParameterArray:nil 
     withSuccessInvocation:[OFInvocation invocationForTarget:OFAnnouncementService.sharedInstance selector:@selector(_combineSectionsAndSort:nextCall:) chained:success]
     withFailureInvocation:failure 
     withRequestType:OFActionRequestSilent 
     withNotice:nil];
}


- (void)_combineSectionsAndSortStickyFirst:(OFPaginatedSeries *)page nextCall:(OFInvocation *)next
{
	
	OFPaginatedSeries* sorted = [self _combineSections:page];
		
	[sorted.objects sortUsingSelector:@selector(compareByCreationDateAndSticky:)];
	
	[next invokeWith:sorted];
	
}

- (void)_combineSectionsAndSort:(OFPaginatedSeries*)page nextCall:(OFInvocation*)next
{
	OFPaginatedSeries* sorted = [self _combineSections:page];
	
	[sorted.objects sortUsingSelector:@selector(compareByCreationDate:)];
	
	[next invokeWith:sorted];
}

- (void)_onAnnouncementsDownloaded:(OFPaginatedSeries*)page
{	
	OFSafeRelease(announcements);
	announcements = [page retain];
	unseenAnnouncementCount = 0;
	
	BOOL showedFullscreen = NO;
	for (OFAnnouncement* announcement in announcements)
	{
		unseenAnnouncementCount += announcement.isUnread ? 1 : 0;

		// XXX TODO cut for field-runners 2.4 release
		if (NO)//announcement.isImportant && announcement.isUnread && !showedFullscreen)	// full-screen
		{
			//announcement.isUnread = NO; //Removed because isUnread is readonly and code does not run anyway.
			[OpenFeint setLastAnnouncementDateForLocalUser:announcement.date];
			--unseenAnnouncementCount;

			// developer is overriding the announcement screen
			if (![OpenFeint isDashboardHubOpen] &&	// cannot override announcement screen if we're prompting from within dashboard
				[[OpenFeint getDelegate] respondsToSelector:@selector(showCustomScreenForAnnouncement:)] &&
				[[OpenFeint getDelegate] showCustomScreenForAnnouncement:announcement])
			{
				showedFullscreen = YES;
			}
			else
			{
				OFAnnouncementDetailController* modal = [OFAnnouncementDetailController announcementDetail:announcement];
                modal.showCloseButton = YES;
				modal.title = @"Announcement";
				OFNavigationController* navController = [[[OFNavigationController alloc] initWithRootViewController:modal] autorelease];
				
				[OFNavigationController addCloseButtonToViewController:modal target:[OpenFeint class] action:@selector(dismissRootControllerOrItsModal) leftSide:NO systemItem:UIBarButtonSystemItemDone];

				if ([OpenFeint isDashboardHubOpen])
				{
					[[OpenFeint getRootController] presentModalViewController:navController animated:YES];
				}
				else
				{
					[OpenFeint presentRootControllerWithModal:navController];
				}

				showedFullscreen = YES;
			}
		}
	}

    [OpenFeint setUnreadAnnouncementCount:unseenAnnouncementCount];
}

+ (OFRequestHandle*)downloadAnnouncements
{
//	OFDelegate chainedSuccess([OFAnnouncementService sharedInstance], @selector(_onAnnouncementsDownloaded:));
//	OFDelegate successFirst([OFAnnouncementService sharedInstance], @selector(_combineSectionsAndSortStickyFirst:nextCall:), chainedSuccess.getInvocation());	
	
    OFInvocation* inner = [OFInvocation invocationForTarget:OFAnnouncementService.sharedInstance selector:@selector(_onAnnouncementsDownloaded:)];
	return [self downloadAnnouncementsOnSuccessInvocation:[OFInvocation invocationForTarget:OFAnnouncementService.sharedInstance selector:@selector(_combineSectionsAndSortStickyFirst:nextCall:) chained:inner]
									  onFailureInvocation:nil];
}




+ (void)markAllAnnouncementsAsRead
{
	[self sharedInstance]->unseenAnnouncementCount = 0;
    [OpenFeint setUnreadAnnouncementCount:[self sharedInstance]->unseenAnnouncementCount];

    // This won't mark all announcements as read on the server.
}

+ (void)clearLocalAnnouncements
{
	[OFAnnouncementService markAllAnnouncementsAsRead];
	OFSafeRelease([OFAnnouncementService sharedInstance]->announcements);
}

@end
