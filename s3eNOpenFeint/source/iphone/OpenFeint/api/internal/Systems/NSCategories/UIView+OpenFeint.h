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
#pragma once

#import "OpenFeint.h"

//TODO: the entire contents of OFViewHelper should be moved here eventually

typedef struct {
    CGRect frame;
    CGAffineTransform transform;
    float deltaX;
    float deltaY;
    
} OFUIViewLocation;

@interface UIView (OpenFeint)
-(UIView*)findViewByTag:(int) targetTag;
-(UIView*)findViewByClass:(Class) viewClass;
-(UIView*)findSuperviewByClass:(Class) viewClass;

-(void)setDelegateForAllTextFields:(id<UITextFieldDelegate>)delegate;
-(void)setReturnKeyForAllTextFields:(UIReturnKeyType)lastKey;

-(UIScrollView*)findFirstScrollView;
-(BOOL)resignFirstResponderRecursive;
-(void)setEnabledForAllControls:(BOOL)isEnabled;
-(CGSize)sizeThatFitsTight;

#pragma mark debugging tools
-(void)debugShowParents;
-(void)debugShowAllChildren;

- (NSString*)detailedDescription;
- (BOOL)isRotatedInternally;
//This calculates the appropriate location for a subview within a main view (usually the application window)
//Since the application window itself never rotates, it is necessary that OpenFeint know the desired orientation of the device before calling
//This will give you back the location desired in the frame.  Note that if the subView size is different from the return frame size (such as displaying a 320 wide on landscape)
// then setting the frame origin will not work properly.  In fact, depending on rotation it could disappear completely.  To set the subView properly, you should set the center
// with  subView.center = CGPointMake(location.origin.frame.x + location.frame.size.width * 0.5, location.origin.frame.y + location.frame.size.height * 0.5)
//After applying the center, apply the transform.
//
//This is returning frames for historical reasons.
- (OFUIViewLocation) findSubviewLocation:(UIView*)subView position:(ENotificationPosition)position deltaRange:(float)deltaRange;

// Find the transform from the device's portrait orientation to this view.
- (CGAffineTransform)calculateViewTransformFromMainScreen;

// Get the transform to get from this view's coordinate system to the device's main window in the orientation
// that is specified for the dashboard.
- (CGAffineTransform)calculateTransformFromViewToOpenFeintDashboardOrientation;

// If orientation is axis aligned, return the orientation if corresponds to.  Otherwise, identity.
+ (CGAffineTransform)transformToInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end
