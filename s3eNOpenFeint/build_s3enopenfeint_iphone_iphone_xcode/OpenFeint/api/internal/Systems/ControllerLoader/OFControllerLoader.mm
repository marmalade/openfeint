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

#import "OFControllerLoader.h"
#import "OpenFeint+Private.h"
#import <objc/runtime.h>
#import "OFTableCellHelper.h"

namespace
{
	NSString* gSuffixString = @"";
	NSString* gClassNamePrefixString = @"";
	NSString* gOverrideSuffixString = nil;
	NSString* gOverrideClassNamePrefixString = nil;
	NSMutableSet* gAdditionalResourceBundles = nil;
}

template <typename _T>
static _T* loadObjectFromNib(NSString* nibName, id owner)
{
	if(owner == nil)
	{
		// citron note: This suppresses tons of console spam
		owner = @"";
	}
	
	NSBundle * bundle = [OpenFeint getResourceBundle];

	NSString* nibPath = [bundle pathForResource:nibName ofType:@"nib"];
	if (!nibPath)
	{
		bundle = [NSBundle mainBundle];
		nibPath = [bundle pathForResource:nibName ofType:@"nib"];
	}
	
	if (!nibPath && gAdditionalResourceBundles)
	{
		NSBundle * thisBundle;
		NSEnumerator *enumerator = [gAdditionalResourceBundles objectEnumerator];
		while (nibPath == nil && (thisBundle = [enumerator nextObject]))
		{
			bundle = thisBundle;
			nibPath = [thisBundle pathForResource:nibName ofType:@"nib"];
		}
	}
	
	if ([nibPath length] > 0)
	{
		NSArray* objects = [bundle loadNibNamed:nibName owner:owner options:nil];

		for(unsigned int i = 0; i < [objects count]; ++i)
		{
			NSObject* obj = [objects objectAtIndex:i];
			if([obj isKindOfClass:[_T class]]) 
			{
				return static_cast<_T*>(obj);
			}
		}
	}
	
	return nil;
}

static UITableViewCell* tryLoadCell(NSString* cellName, NSObject* filesOwner, NSString* nibSuffix, NSString* classPrefix)
{
	UITableViewCell* tableCell = nil;
	
	if ([OpenFeint isLargeScreen]) 
	{
        NSString* nibName = [NSString stringWithFormat:@"%@IPadCell%@", cellName, nibSuffix];
        tableCell = loadObjectFromNib<UITableViewCell>(nibName, filesOwner);
    }
	else if([OpenFeint isInLandscapeMode])
	{
		NSString* nibName = [NSString stringWithFormat:@"%@LandscapeCell%@", cellName, nibSuffix];
		tableCell = loadObjectFromNib<UITableViewCell>(nibName, filesOwner);
	}
	
	if (!tableCell)
	{
		NSString* nibName = [NSString stringWithFormat:@"%@Cell%@", cellName, nibSuffix];
		tableCell = loadObjectFromNib<UITableViewCell>(nibName, filesOwner);
	}
	
	if(!tableCell)
	{
		NSString* cellClassName = [NSString stringWithFormat:@"%@%@Cell", classPrefix, cellName];
		Class cellClass = (Class)objc_lookUpClass([cellClassName UTF8String]);
		if(cellClass)
		{
			tableCell = (UITableViewCell*)class_createInstance(cellClass, 0);
			OFAssert([tableCell isKindOfClass:[OFTableCellHelper class]], "We don't support loading non-OFTableCellHelpers via OFControllerLoader::loadCell!");
			
			[(OFTableCellHelper*)tableCell initOFTableCellHelper:cellName];
            
			[tableCell autorelease];
			
			SEL setOwner = @selector(setOwner:);
			if([tableCell respondsToSelector:setOwner])
			{
				[tableCell performSelector:setOwner withObject:filesOwner];
			}
		}
	}
	
	if(tableCell)
	{
		OFAssert([tableCell.reuseIdentifier isEqualToString:cellName], "Table cell '%@' has an incorrect reuse identifier. Expected '%@' but was '%@'", cellName, cellName, tableCell.reuseIdentifier);
	}
    
	return tableCell;
}

UITableViewCell* OFControllerLoader::loadCell(NSString* cellName, NSObject* filesOwner)
{
	UITableViewCell* tableCell = nil;
	
	
	if (gOverrideClassNamePrefixString && gOverrideSuffixString)
	{
		tableCell = tryLoadCell(cellName, filesOwner, gOverrideSuffixString, gOverrideClassNamePrefixString);
	}
	
	if (!tableCell)
	{
		tableCell = tryLoadCell(cellName, filesOwner, gSuffixString, gClassNamePrefixString);
	}
	
	OFAssert(tableCell, "Failed trying to load table cell %@", cellName);
    
    if ([OpenFeint isLargeScreen] && tableCell.frame.size.height < 60.f)
    {
        CGRect newCellFrame = tableCell.frame;
        newCellFrame.size.height = 60.f;
        tableCell.frame = newCellFrame;
    }
    
	return tableCell;
}

static UIViewController* tryLoadController(NSString* name, NSObject* filesOwner, NSString* nibSuffix, NSString* classPrefix)
{
    
	UIViewController* controller = nil;
    
    if ([OpenFeint isLargeScreen]) {
        NSString* iPadNibName = [NSString stringWithFormat:@"%@ControllerIPad%@", name, nibSuffix];
        controller = loadObjectFromNib<UIViewController>(iPadNibName, filesOwner);
    }
	else if([OpenFeint isInLandscapeMode])
	{
		NSString* landscapeNibName = [NSString stringWithFormat:@"%@ControllerLandscape%@", name, nibSuffix];
		controller = loadObjectFromNib<UIViewController>(landscapeNibName, filesOwner);
	}
	
	if (!controller)
	{
		NSString* nibName = [NSString stringWithFormat:@"%@Controller%@", name, nibSuffix];
		controller = loadObjectFromNib<UIViewController>(nibName, filesOwner);
	}
	
	
	if(!controller)
	{
		Class controllerClass = (Class)objc_lookUpClass([[NSString stringWithFormat:@"%@%@Controller", classPrefix, name] UTF8String]);
		if(controllerClass)
		{
			controller = (UIViewController*)class_createInstance(controllerClass, 0);
			[controller init];
			[controller autorelease];
		}
	}
	
	return controller;
}

UIViewController* OFControllerLoader::load(NSString* name, NSObject* filesOwner)
{
	UIViewController* controller = nil;
	
	if (gOverrideClassNamePrefixString && gOverrideSuffixString)
	{
		controller = tryLoadController(name, filesOwner, gOverrideSuffixString, gOverrideClassNamePrefixString);
	}
	
	if (!controller)
	{
		controller = tryLoadController(name, filesOwner, gSuffixString, gClassNamePrefixString);
	}
	
	OFAssert(controller, "Failed trying to load controller %@", name);
	
	return controller;
}

SEL buildSetterSelector(NSString *key)
{
    NSString *front = [key substringToIndex:1];
    NSString *back = [key substringFromIndex:1];
    NSString *combined = [NSString stringWithFormat:@"set%@%@:", [front capitalizedString], back];
    return NSSelectorFromString(combined);
}

UIViewController* OFControllerLoader::loadWithParamsDictionary(NSString *name, NSDictionary* params, NSObject* filesOwner)
{
    UIViewController* controller = load(name, filesOwner);
    if(controller)
    {
        if([controller respondsToSelector:@selector(customLoader:)]) 
        {
            [controller performSelector:@selector(customLoader:) withObject: params];
        }
        else {
            for(NSString* key in params)
            {
                SEL setter = buildSetterSelector(key);                
                if([controller respondsToSelector:setter])
                {
                    [controller performSelector:setter withObject:[params objectForKey:key]];
                }
                else 
                {
                    NSLog(@"ControllerLoader received unknown key %@ = %@", key, [params objectForKey:key]);
                }

            }
        }

    }
    
    return controller;
}

UIView* tryLoadView(NSString* viewName, NSObject* filesOwner, NSString* nibSuffix)
{
	UIView* view = nil;
    
    if ([OpenFeint isLargeScreen])
    {
        NSString* largeNibName = [NSString stringWithFormat:@"%@IPad%@", viewName, nibSuffix];
		view = loadObjectFromNib<UIView>(largeNibName, filesOwner);
    }
    
    if (!view && [OpenFeint isInLandscapeMode])
	{
		NSString* landscapeNibName = [NSString stringWithFormat:@"%@Landscape%@", viewName, nibSuffix];
		view = loadObjectFromNib<UIView>(landscapeNibName, filesOwner);
	}
	
	if (!view)
	{
		view = loadObjectFromNib<UIView>([NSString stringWithFormat:@"%@%@", viewName, nibSuffix], filesOwner);
	}	
	
	return view;
}

UIView* OFControllerLoader::loadView(NSString* viewName, NSObject* filesOwner)
{
	UIView* view = nil;
	
	if (gOverrideSuffixString)
	{
		view = tryLoadView(viewName, filesOwner, gOverrideSuffixString);
	}
	
	if (!view)
	{
		view = tryLoadView(viewName, filesOwner, gSuffixString);
	}

	// No use case for this yet.
//	if (!view)
//	{
//		Class viewClass = getViewClass(viewName);
//		if(viewClass)
//		{
//			view = (UIView*)class_createInstance(viewClass, 0);
//			[view init];
//			[view autorelease];
//		}
//	}
	
	OFAssert(view, "Failed trying to load view %@", viewName);
	
	return view;
}

Class OFControllerLoader::getViewClass(NSString* viewName)
{
	Class viewClass = (Class)objc_lookUpClass([[NSString stringWithFormat:@"%@%@View", gOverrideClassNamePrefixString, viewName] UTF8String]);
	if(!viewClass)
	{
		viewClass = (Class)objc_lookUpClass([[NSString stringWithFormat:@"%@%@View", gClassNamePrefixString, viewName] UTF8String]);
	}
	return viewClass;
}

Class OFControllerLoader::getControllerClass(NSString* controllerName)
{
	Class controllerClass = (Class)objc_lookUpClass([[NSString stringWithFormat:@"%@%@Controller", gOverrideClassNamePrefixString, controllerName] UTF8String]);
	if(!controllerClass)
	{
		controllerClass = (Class)objc_lookUpClass([[NSString stringWithFormat:@"%@%@Controller", gClassNamePrefixString, controllerName] UTF8String]);
	}
	return controllerClass;
}

void OFControllerLoader::setAssetFileSuffix(NSString* suffixString)
{
	[gSuffixString release];
	gSuffixString = [suffixString retain];
}

void OFControllerLoader::setClassNamePrefix(NSString* prefixString)
{
	[gClassNamePrefixString release];
	gClassNamePrefixString = [prefixString retain];
}

void OFControllerLoader::setOverrideAssetFileSuffix(NSString* suffixString)
{
	[gOverrideSuffixString release];
	gOverrideSuffixString = [suffixString retain];
}

void OFControllerLoader::setOverrideClassNamePrefix(NSString* prefixString)
{
	[gOverrideClassNamePrefixString release];
	gOverrideClassNamePrefixString = [prefixString retain];
}

void OFControllerLoader::registerResourceBundle(NSBundle* bundle)
{
	if (gAdditionalResourceBundles == nil)
	{
		gAdditionalResourceBundles = [[NSMutableSet alloc] initWithCapacity:10];
	}
	[gAdditionalResourceBundles addObject:bundle];
}

