////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@class UINavigationController, UIViewController;

@interface UINavigationController (OpenFeint)

// Returns the UIViewController immediately preceding childViewController in self.viewControllers.
// Returns nil if childViewController is not in self.viewControllers or if it's the root view controller.
- (UIViewController*)previousViewController:(UIViewController*)childViewController;

@end
