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
#import "OFViewDataGetter.h"
#import "UIView+OpenFeint.h"
#include <objc/runtime.h>
#import "OFDependencies.h"

@interface OFViewDataGetter()
@property (nonatomic, retain) NSDictionary* dataMap;
@property (nonatomic, retain) UIView* rootView;
@end


@implementation OFViewDataGetter
@synthesize dataMap = mDataMap;
@synthesize rootView = mRootView;

+(id) getterWithView:(UIView*) view map:(NSDictionary*) map
{
    return [[[OFViewDataGetter alloc] initWithView:view map:map] autorelease];
    
}

-(id) initWithView:(UIView*) view map:(NSDictionary*) viewDataMap
{
    if((self = [super init]))
    {
        self.rootView = view;
        self.dataMap = viewDataMap;
    }
    return self;
}

-(void) dealloc
{
    self.rootView = nil;
    self.dataMap = nil;
    [super dealloc];
}
                        
                         

- (void) serializeToOFISerializer:(id<OFISerializer>) serializer
{
    //for each item in map, read the view, send the value based on class type
    //the C++ version used a fixed list for expandability, which seems like overkill for what we have
    for(NSNumber* viewTag in self.dataMap)
    {
        NSString* name = [self.dataMap objectForKey:viewTag];
        UIView* namedView = [self.rootView findViewByTag:viewTag.intValue];
        if([namedView isKindOfClass:UILabel.class])
        {
            [serializer ioNSStringToKey:name object:[(UILabel*)namedView text]];
        }
        else if([namedView isKindOfClass:UITextField.class])
        {
            [serializer ioNSStringToKey:name object:[(UITextField*)namedView text]];
        }
        else if([namedView isKindOfClass:UITextView.class])
        {
            [serializer ioNSStringToKey:name object:[(UITextView*)namedView text]];
        }
        else if([namedView isKindOfClass:UISwitch.class])
        {            
            [serializer ioBoolToKey:name value:((UISwitch*)namedView).on];
        }
        else {
            OFLog(@"Attempting to get a value on an unsupported view class (%@)", [namedView class]);
            [[NSException exceptionWithName:@"Invalid view class" 
                                    reason:[NSString stringWithFormat:@"OFViewDataGetter does not support %@", [namedView class]]
                                  userInfo:nil] raise];
        }
    }
}



@end
