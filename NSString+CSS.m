//
//  NSString+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 26.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString+CSS.h"


@implementation NSString (CSS)

- (NSComparisonResult)numericCompare:(NSString *)aString {
	return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end
