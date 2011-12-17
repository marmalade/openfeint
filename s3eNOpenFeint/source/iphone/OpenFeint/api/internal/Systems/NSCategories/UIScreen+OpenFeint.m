//
//  UIScreen+OpenFeint.mm
//  Spotlight
//
//  Created by Benjamin Morse on 10/29/10.
//  Copyright 2010 Aurora Feint. All rights reserved.
//

#import <UIKit/UIKit.h>

@implementation UIScreen (OpenFeint)

- (CGFloat)safeScale
{
	if ([self respondsToSelector:@selector(scale)])
	{
		return [self scale];
	}
	return 1.0;
}

@end
