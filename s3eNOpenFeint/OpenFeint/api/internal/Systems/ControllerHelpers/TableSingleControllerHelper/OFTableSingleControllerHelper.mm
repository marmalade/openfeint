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

#import "OFDependencies.h"
#import "OFTableSingleControllerHelper.h"
#import "OFTableSingleControllerHelper+Overridables.h"
#import "OFService+Overridables.h"
#import "OFPaginatedSeries.h"

@implementation OFTableSingleControllerHelper

@synthesize resourceId;

- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	OFAssert(isIncremental == false, "Incremental loading is not supported yet for single controllers");
	
	OFSafeRelease(mSections);
	
	if([resources count])
	{
		mSections = [[self tableSectionDescriptionsForResource:(OFResource*)[resources objectAtIndex:0]] retain];
	}
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	OFAssert(self.resourceId != nil, "Must specify a resource for the TableSingleController to display");
	OFService* service = [self getService];
	[[service class] getShowWithId:self.resourceId onSuccess:success onFailure:failure];
}

- (void)dealloc
{
	self.resourceId = nil;
	[super dealloc];
}

@end
