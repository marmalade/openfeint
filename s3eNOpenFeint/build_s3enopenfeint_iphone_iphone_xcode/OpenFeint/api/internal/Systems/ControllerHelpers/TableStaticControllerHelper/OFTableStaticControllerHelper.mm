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
#import "OFTableStaticControllerHelper.h"
#import "OFTableStaticControllerHelper+Overridables.h"
#import "OFService+Overridables.h"
#import "OFPaginatedSeries.h"

@implementation OFTableStaticControllerHelper

- (OFResource*) getResourceFromSection:(NSArray*)sectionCells atRow:(NSUInteger)row
{
	return nil;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	OFSafeRelease(mSections);
	mSections = [[self buildTableSectionDescriptions] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	//Give static tables a chance to implement a header without enforcing the "empty data" footer.
	if(self.tableView.tableHeaderView == nil)
	{
		[self _createAndDisplayTableHeader];
	}
}

- (void)dealloc
{
	[super dealloc];
}

@end
