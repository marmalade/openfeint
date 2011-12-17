//  Copyright 2009-2011 Aurora Feint, Inc.
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

#import <UIKit/UIKit.h>

@interface OFColoredTextLabel : UIView {
@private
    NSString* mHeaderText;
    NSString* mBodyText;
    UIColor* mHeaderColor;
    UIColor* mBodyColor;
    UILabel* mLabelTemplate;
}
@property(nonatomic, retain) UILabel* labelTemplate;
@property(nonatomic, retain) NSString* headerText;
@property(nonatomic, retain) NSString* bodyText;
@property(nonatomic, retain) UIColor* headerColor;
@property(nonatomic, retain) UIColor* bodyColor;
- (void)rebuild;  //must be called after setting any of the properties and before the next draw

@end
